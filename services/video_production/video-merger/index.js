/**
 * Video Merger Lambda Function
 *
 * Downloads video segments from S3, concatenates them with FFmpeg,
 * and uploads the result back to S3.
 *
 * Designed to run on AWS Lambda with FFmpeg layer.
 */

const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const { randomUUID } = require('crypto');
const { Readable } = require('stream');

// Configure S3 client with LocalStack support
const s3ClientConfig = {
  region: process.env.AWS_REGION || 'us-east-1'
};

// Use LocalStack endpoint if AWS_ENDPOINT_URL is set (for local development)
if (process.env.AWS_ENDPOINT_URL) {
  s3ClientConfig.endpoint = process.env.AWS_ENDPOINT_URL;
  s3ClientConfig.forcePathStyle = true; // Required for LocalStack
}

const s3Client = new S3Client(s3ClientConfig);

/**
 * Lambda handler
 *
 * Expected event format:
 * {
 *   input_videos: ["s3://bucket/path1.mp4", "s3://bucket/path2.mp4"],
 *   output_bucket: "jiki-videos",
 *   output_key: "pipelines/123/nodes/456/output.mp4"
 * }
 */
exports.handler = async (event) => {
  const { input_videos, output_bucket, output_key } = event;

  // Validate inputs
  if (!Array.isArray(input_videos) || input_videos.length < 2) {
    return {
      error: 'At least 2 input videos required',
      statusCode: 400
    };
  }

  if (!output_bucket || !output_key) {
    return {
      error: 'output_bucket and output_key are required',
      statusCode: 400
    };
  }

  const tempDir = '/tmp';
  const inputPaths = [];
  const outputPath = path.join(tempDir, `output-${randomUUID()}.mp4`);
  const concatFilePath = path.join(tempDir, `concat-${randomUUID()}.txt`);

  try {
    console.error(`[VideoMerger] Processing ${input_videos.length} videos`);

    // 1. Download videos from S3
    for (let i = 0; i < input_videos.length; i++) {
      const s3Url = input_videos[i];
      const localPath = path.join(tempDir, `input-${i}-${randomUUID()}.mp4`);

      console.error(`[VideoMerger] Downloading ${s3Url} to ${localPath}`);
      await downloadFromS3(s3Url, localPath);
      inputPaths.push(localPath);
    }

    // 2. Create FFmpeg concat file
    const concatContent = inputPaths.map(p => `file '${p}'`).join('\n');
    await fs.writeFile(concatFilePath, concatContent, 'utf-8');
    console.error(`[VideoMerger] Created concat file with ${inputPaths.length} videos`);

    // 3. Run FFmpeg to merge videos
    const duration = await mergeVideosWithFFmpeg(concatFilePath, outputPath);
    console.error(`[VideoMerger] Merge completed, duration: ${duration}s`);

    // 4. Get output file stats
    const stats = await fs.stat(outputPath);
    const size = stats.size;

    // 5. Upload to S3
    console.error(`[VideoMerger] Uploading to s3://${output_bucket}/${output_key}`);
    await uploadToS3(outputPath, output_bucket, output_key);

    // 6. Clean up temp files
    await cleanupFiles([...inputPaths, outputPath, concatFilePath]);

    return {
      s3_key: output_key,
      duration: duration,
      size: size,
      statusCode: 200
    };

  } catch (error) {
    console.error('[VideoMerger] Error:', error);

    // Clean up on error
    try {
      await cleanupFiles([...inputPaths, outputPath, concatFilePath]);
    } catch (cleanupError) {
      console.warn('[VideoMerger] Cleanup error:', cleanupError);
    }

    return {
      error: error.message,
      statusCode: 500
    };
  }
};

/**
 * Download file from S3
 * @param {string} s3Url - S3 URL (s3://bucket/key)
 * @param {string} localPath - Local file path
 */
async function downloadFromS3(s3Url, localPath) {
  const match = s3Url.match(/^s3:\/\/([^/]+)\/(.+)$/);
  if (!match) {
    throw new Error(`Invalid S3 URL: ${s3Url}`);
  }

  const [, bucket, key] = match;

  const command = new GetObjectCommand({ Bucket: bucket, Key: key });
  const response = await s3Client.send(command);

  // Convert stream to buffer and write to file
  const chunks = [];
  for await (const chunk of response.Body) {
    chunks.push(chunk);
  }
  const buffer = Buffer.concat(chunks);
  await fs.writeFile(localPath, buffer);
}

/**
 * Upload file to S3
 * @param {string} localPath - Local file path
 * @param {string} bucket - S3 bucket name
 * @param {string} key - S3 key
 */
async function uploadToS3(localPath, bucket, key) {
  const fileBuffer = await fs.readFile(localPath);

  const command = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    Body: fileBuffer,
    ContentType: 'video/mp4'
  });

  await s3Client.send(command);
}

/**
 * Merge videos using FFmpeg
 * @param {string} concatFilePath - Path to concat demuxer file
 * @param {string} outputPath - Output file path
 * @returns {Promise<number>} Duration in seconds
 */
function mergeVideosWithFFmpeg(concatFilePath, outputPath) {
  return new Promise((resolve, reject) => {
    const args = [
      '-f', 'concat',
      '-safe', '0',
      '-i', concatFilePath,
      '-c', 'copy',
      '-y', // Overwrite output file
      outputPath
    ];

    console.error(`[FFmpeg] Running: ffmpeg ${args.join(' ')}`);

    const ffmpeg = spawn('ffmpeg', args);
    let stderr = '';

    ffmpeg.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    ffmpeg.on('close', (code) => {
      if (code !== 0) {
        console.error('[FFmpeg] stderr:', stderr);
        reject(new Error(`FFmpeg failed with code ${code}`));
        return;
      }

      // Extract duration from FFmpeg output
      const durationMatch = stderr.match(/Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})/);
      let duration = 0;

      if (durationMatch) {
        const hours = parseInt(durationMatch[1], 10);
        const minutes = parseInt(durationMatch[2], 10);
        const seconds = parseFloat(durationMatch[3]);
        duration = hours * 3600 + minutes * 60 + seconds;
      }

      resolve(duration);
    });

    ffmpeg.on('error', (error) => {
      reject(new Error(`FFmpeg spawn error: ${error.message}`));
    });
  });
}

/**
 * Clean up temporary files
 * @param {string[]} paths - Array of file paths to delete
 */
async function cleanupFiles(paths) {
  for (const filePath of paths) {
    try {
      await fs.unlink(filePath);
    } catch (error) {
      // Ignore errors (file might not exist)
    }
  }
}
