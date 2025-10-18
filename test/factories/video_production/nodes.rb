FactoryBot.define do
  factory :video_production_node, class: 'VideoProduction::Node' do
    association :pipeline, factory: :video_production_pipeline

    title { "Test Node" }
    type { 'asset' }
    provider { 'direct' }
    inputs { {} }
    config { {} }
    status { 'pending' }

    trait :merge_videos do
      type { 'merge-videos' }
      provider { 'ffmpeg' }
      config { {} }
    end

    trait :talking_head do
      type { 'generate-talking-head' }
      provider { 'heygen' }
      config do
        {
          'avatar_id' => 'avatar-1',
          'voice_id' => 'voice-1'
        }
      end
    end

    trait :generate_animation do
      type { 'generate-animation' }
      provider { 'veo3' }
      config { {} }
    end

    trait :generate_voiceover do
      type { 'generate-voiceover' }
      provider { 'elevenlabs' }
      config do
        {
          'voice_id' => 'voice-1'
        }
      end
    end

    trait :completed do
      status { 'completed' }
      metadata do
        {
          'startedAt' => 1.hour.ago.iso8601,
          'completedAt' => Time.current.iso8601,
          'cost' => 0.05
        }
      end
      output do
        {
          'type' => 'video',
          's3Key' => 'output/test.mp4',
          'duration' => 60.0,
          'size' => 5_242_880
        }
      end
    end
  end
end
