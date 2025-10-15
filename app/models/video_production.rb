module VideoProduction
  # Node type input schemas - single source of truth
  # These define the expected structure of the `inputs` JSONB field for each node type
  INPUT_SCHEMAS = {
    'asset' => {
      # Asset nodes have no inputs - they are source nodes
    },
    'talking-head' => {
      'script' => {
        type: :array,
        required: false,
        description: 'Reference to asset node(s) with script text'
      }
    },
    'generate-animation' => {
      'prompt' => {
        type: :array,
        required: false,
        description: 'Reference to asset node(s) with animation prompt'
      },
      'referenceImage' => {
        type: :array,
        required: false,
        description: 'Optional reference image for animation generation'
      }
    },
    'generate-voiceover' => {
      'script' => {
        type: :array,
        required: false,
        description: 'Reference to asset node(s) with voiceover script'
      }
    },
    'render-code' => {
      'config' => {
        type: :array,
        required: false,
        description: 'Reference to asset node(s) with Remotion config JSON'
      }
    },
    'mix-audio' => {
      'video' => {
        type: :array,
        required: true,
        min_items: 1,
        description: 'Reference to video node'
      },
      'audio' => {
        type: :array,
        required: true,
        min_items: 1,
        description: 'Reference to audio node'
      }
    },
    'merge-videos' => {
      'segments' => {
        type: :array,
        required: true,
        min_items: 2,
        description: 'Array of video node references to concatenate'
      }
    },
    'compose-video' => {
      'background' => {
        type: :array,
        required: true,
        min_items: 1,
        description: 'Background video node reference'
      },
      'overlay' => {
        type: :array,
        required: true,
        min_items: 1,
        description: 'Overlay video node reference (e.g., talking head)'
      }
    }
  }.freeze

  # Valid node types
  NODE_TYPES = INPUT_SCHEMAS.keys.freeze
end
