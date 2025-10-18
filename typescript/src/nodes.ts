/**
 * Video Production Node Types
 * Auto-generated from Rails schemas
 * DO NOT EDIT MANUALLY
 *
 * Generated at: 2025-10-18T14:41:21Z
 * Source: app/commands/video_production/node/schemas/
 */

// ============================================================================
// Video Production Node Types
// ============================================================================

/** Asset node type (inputs + provider-specific config) */
export type AssetNode = {
  inputs: {};
} & (
  | { provider: 'direct'; config: {} });

/** ComposeVideo node type (inputs + provider-specific config) */
export type ComposeVideoNode = {
  inputs: {
    background: string;
    overlay: string;
  };
} & (
  | { provider: 'ffmpeg'; config: {
      position?: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' | 'center';
      scale?: string;
    } });

/** GenerateAnimation node type (inputs + provider-specific config) */
export type GenerateAnimationNode = {
  inputs: {
    prompt?: string;
    referenceImage?: string;
  };
} & (
  | { provider: 'veo3'; config: {
      model?: 'standard' | 'premium';
      aspect_ratio?: '16:9' | '9:16' | '1:1';
    } }
  | { provider: 'runway'; config: {
      generation?: 'gen2' | 'gen3';
    } }
  | { provider: 'stability'; config: {} });

/** GenerateTalkingHead node type (inputs + provider-specific config) */
export type GenerateTalkingHeadNode = {
  inputs: {
    script?: string;
  };
} & (
  | { provider: 'heygen'; config: {
      avatar_id: string;
      voice_id: string;
    } });

/** GenerateVoiceover node type (inputs + provider-specific config) */
export type GenerateVoiceoverNode = {
  inputs: {
    script?: string;
  };
} & (
  | { provider: 'elevenlabs'; config: {
      voice_id: string;
      model?: 'eleven_monolingual_v1' | 'eleven_multilingual_v2';
    } });

/** MergeVideos node type (inputs + provider-specific config) */
export type MergeVideosNode = {
  inputs: {
    segments: string[];
  };
} & (
  | { provider: 'ffmpeg'; config: {
      output_format?: 'mp4' | 'webm';
      preset?: 'ultrafast' | 'superfast' | 'veryfast' | 'faster' | 'fast' | 'medium' | 'slow' | 'slower' | 'veryslow';
    } });

/** MixAudio node type (inputs + provider-specific config) */
export type MixAudioNode = {
  inputs: {
    video: string;
    audio: string;
  };
} & (
  | { provider: 'ffmpeg'; config: {
      audio_codec?: 'aac' | 'mp3' | 'opus';
      volume?: number;
    } });

/** RenderCode node type (inputs + provider-specific config) */
export type RenderCodeNode = {
  inputs: {
    config?: string;
  };
} & (
  | { provider: 'remotion'; config: {
      composition: string;
      fps?: number;
      quality?: number;
    } });
