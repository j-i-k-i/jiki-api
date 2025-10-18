module VideoProduction
  # Valid node types
  NODE_TYPES = %w[
    asset
    generate-talking-head
    generate-animation
    generate-voiceover
    render-code
    mix-audio
    merge-videos
    compose-video
  ].freeze

  # REFERENCE: Input schemas to be migrated to individual schema classes
  # These schemas should be moved to app/commands/video_production/node/schemas/
  # See Schemas::MergeVideos for the pattern
  #
  # Type system:
  #   - type: :single = expects a single node UUID (string)
  #   - type: :multiple = expects an array of node UUIDs with min_count/max_count
  INPUT_SCHEMAS = {
    'asset' => {
      # Asset nodes have no inputs - they are source nodes
    },
    'generate-talking-head' => {
      'script' => {
        type: :single,
        required: false,
        description: 'Reference to asset node with script text'
      }
    },
    'generate-animation' => {
      'prompt' => {
        type: :single,
        required: false,
        description: 'Reference to asset node with animation prompt'
      },
      'referenceImage' => {
        type: :single,
        required: false,
        description: 'Optional reference image for animation generation'
      }
    },
    'generate-voiceover' => {
      'script' => {
        type: :single,
        required: false,
        description: 'Reference to asset node with voiceover script'
      }
    },
    'render-code' => {
      'config' => {
        type: :single,
        required: false,
        description: 'Reference to asset node with Remotion config JSON'
      }
    },
    'mix-audio' => {
      'video' => {
        type: :single,
        required: true,
        description: 'Reference to video node'
      },
      'audio' => {
        type: :single,
        required: true,
        description: 'Reference to audio node'
      }
    },
    'merge-videos' => {
      'segments' => {
        type: :multiple,
        required: true,
        min_count: 2,
        max_count: nil,
        description: 'Array of video node references to concatenate'
      }
    },
    'compose-video' => {
      'background' => {
        type: :single,
        required: true,
        description: 'Background video node reference'
      },
      'overlay' => {
        type: :single,
        required: true,
        description: 'Overlay video node reference (e.g., talking head)'
      }
    }
  }.freeze
end
