# Video Production Pipeline

This file documents the video production pipeline system for orchestrating AI-generated video content.

## Overview

The video production system allows admins to create and execute complex video generation workflows through a visual pipeline editor. The Rails API manages pipeline state, coordinates background jobs, and integrates with external APIs (HeyGen, ElevenLabs, Veo 3) and Lambda functions (FFmpeg processing).

## Architecture

```
┌─────────────────────────────────────────────────┐
│          Next.js Visual Editor                  │
│     (code-videos repo - UI only)                │
│  • React Flow pipeline designer                 │
│  • Read-only database access                    │
│  • Calls Rails API for execution                │
└─────────────────┬───────────────────────────────┘
                  │
                  │ POST /v1/admin/video_production/.../nodes
                  │ GET  /v1/admin/video_production/...
                  ↓
┌─────────────────────────────────────────────────┐
│           Rails API (this repo)                 │
│  • CRUD operations for pipelines/nodes          │
│  • Input validation                             │
│  • Database writes (status, metadata, output)   │
│  • Sidekiq executors & polling jobs             │
└─────────────────┬───────────────────────────────┘
                  │
         ┌────────┼────────┬────────┬──────────┐
         ↓        ↓        ↓        ↓          ↓
    ┌────────┐ ┌─────┐ ┌──────┐ ┌────────┐ ┌────┐
    │ Lambda │ │HeyGen│ │ Veo3 │ │Eleven  │ │ S3 │
    │(FFmpeg)│ │ API  │ │ API  │ │Labs API│ │    │
    └────────┘ └─────┘ └──────┘ └────────┘ └────┘
```

## Services Structure

Lambda functions and deployment configuration live in `services/video_production/`:

```
services/video_production/
├── README.md                    # Deployment guide and architecture
├── template.yaml                # AWS SAM deployment config
└── video-merger/                # FFmpeg video concatenation Lambda
    ├── index.js
    ├── package.json
    └── README.md
```

All Ruby code (executors, API clients, utilities) remains in `app/commands/video_production/`.

## Database Schema

### Shared PostgreSQL Database

Both Next.js (code-videos) and Rails connect to the same database. Column ownership prevents conflicts:

- **Next.js writes**: `type`, `inputs`, `config`, `asset`, `title`
- **Rails writes**: `status`, `metadata`, `output`

### video_production_pipelines

```ruby
create_table :video_production_pipelines, id: :uuid do |t|
  t.string :version, null: false, default: '1.0'
  t.string :title, null: false
  t.jsonb :config, null: false, default: {}
  t.jsonb :metadata, null: false, default: {}
  t.timestamps
end
```

**JSONB Columns:**
- `config`: Storage and working directory settings
- `metadata`: Cost tracking and progress statistics

### video_production_nodes

```ruby
create_table :video_production_nodes, id: :uuid do |t|
  t.uuid :pipeline_id, null: false, foreign_key: true
  t.string :title, null: false

  # Structure (Next.js writes)
  t.string :type, null: false
  t.jsonb :inputs, null: false, default: {}
  t.jsonb :config, null: false, default: {}
  t.jsonb :asset

  # Execution state (Rails writes)
  t.string :status, null: false, default: 'pending'
  t.jsonb :metadata
  t.jsonb :output

  t.timestamps
end
```

**Node Types:**
- `asset` - Static file references
- `talking-head` - HeyGen talking head videos
- `generate-animation` - Veo 3 / Runway animations
- `generate-voiceover` - ElevenLabs text-to-speech
- `render-code` - Remotion code screen animations
- `mix-audio` - FFmpeg audio replacement
- `merge-videos` - FFmpeg video concatenation
- `compose-video` - FFmpeg picture-in-picture overlays

**Status Values:** `pending`, `in_progress`, `completed`, `failed`

## Models

### VideoProduction::Pipeline

```ruby
class VideoProduction::Pipeline < ApplicationRecord
  self.table_name = 'video_production_pipelines'

  has_many :nodes, class_name: 'VideoProduction::Node',
           foreign_key: :pipeline_id, dependent: :destroy

  validates :title, presence: true
  validates :version, presence: true
end
```

Location: `app/models/video_production/pipeline.rb`

### VideoProduction::Node

```ruby
class VideoProduction::Node < ApplicationRecord
  self.table_name = 'video_production_nodes'

  # Prevent Rails STI on 'type' column
  self.inheritance_column = :_type_disabled

  belongs_to :pipeline, class_name: 'VideoProduction::Pipeline',
             foreign_key: :pipeline_id

  validates :uuid, presence: true, uniqueness: { scope: :pipeline_id }
  validates :title, presence: true
  validates :type, presence: true, inclusion: {
    in: %w[asset talking-head generate-animation generate-voiceover
           render-code mix-audio merge-videos compose-video]
  }
  validates :status, inclusion: {
    in: %w[pending in_progress completed failed]
  }
end
```

Location: `app/models/video_production/node.rb`

**Important:** Uses `self.inheritance_column = :_type_disabled` to prevent Rails STI behavior.

## Input Validation

Input schemas are defined in `app/models/video_production.rb`:

```ruby
module VideoProduction
  INPUT_SCHEMAS = {
    'asset' => {},  # No inputs
    'merge-videos' => {
      segments: { type: :array, required: true, min_items: 2 }
    },
    'mix-audio' => {
      video: { type: :array, required: true },
      audio: { type: :array, required: true }
    },
    'compose-video' => {
      background: { type: :array, required: true },
      overlay: { type: :array, required: true }
    },
    'talking-head' => {
      script: { type: :array, required: false }
    },
    'generate-animation' => {
      prompt: { type: :array, required: false },
      referenceImage: { type: :array, required: false }
    },
    'generate-voiceover' => {
      script: { type: :array, required: false }
    },
    'render-code' => {
      config: { type: :array, required: false }
    }
  }.freeze
end
```

Validation is performed by `VideoProduction::Node::ValidateInputs` command, which:
1. Checks for unexpected input slots
2. Validates required inputs
3. Checks array types and minimum items
4. Verifies referenced node UUIDs exist in database

Location: `app/commands/video_production/node/validate_inputs.rb`

## Commands

All commands use the Mandate pattern (see `.context/architecture.md`).

### VideoProduction::Pipeline::Create

Creates a new pipeline with provided parameters.

```ruby
VideoProduction::Pipeline::Create.(
  title: "Ruby Course",
  version: "1.0",
  config: { storage: { bucket: "jiki-videos" } },
  metadata: { totalCost: 0 }
)
```

Location: `app/commands/video_production/pipeline/create.rb`

### VideoProduction::Pipeline::Update

Updates an existing pipeline.

```ruby
VideoProduction::Pipeline::Update.(
  pipeline,
  title: "Updated Title"
)
```

Location: `app/commands/video_production/pipeline/update.rb`

### VideoProduction::Pipeline::Destroy

Deletes a pipeline (cascades to nodes via foreign key).

```ruby
VideoProduction::Pipeline::Destroy.(pipeline)
```

Location: `app/commands/video_production/pipeline/destroy.rb`

### VideoProduction::Node::Create

Creates a node and validates inputs.

```ruby
VideoProduction::Node::Create.(
  pipeline,
  title: "Merge Videos",
  type: "merge-videos",
  inputs: { segments: ["uuid1", "uuid2"] },
  config: { provider: "ffmpeg" }
)
```

Location: `app/commands/video_production/node/create.rb`

**Raises:** `VideoProductionBadInputsError` if validation fails

### VideoProduction::Node::Update

Updates a node, resets status to `pending` if structure fields change.

```ruby
VideoProduction::Node::Update.(
  node,
  config: { provider: "updated" }
)
```

Location: `app/commands/video_production/node/update.rb`

Structure fields that trigger status reset:
- `inputs`
- `config`
- `asset`

### VideoProduction::Node::Destroy

Deletes a node and removes references from other nodes' inputs.

```ruby
VideoProduction::Node::Destroy.(node)
```

Location: `app/commands/video_production/node/destroy.rb`

When a node is deleted:
- If referenced in an array input, UUID is removed from array
- If referenced as a string/direct input, the entire slot is removed

### VideoProduction::Node::ValidateInputs

Validates node inputs against schema.

```ruby
VideoProduction::Node::ValidateInputs.(
  'merge-videos',
  { 'segments' => ['uuid1', 'uuid2'] },
  pipeline.id
)
```

Location: `app/commands/video_production/node/validate_inputs.rb`

**Raises:** `VideoProductionBadInputsError` with comma-separated error messages

## Controllers

### V1::Admin::VideoProduction::PipelinesController

Admin-only CRUD operations for pipelines.

**Actions:**
- `index` - Paginated list (25 per page by default)
- `show` - Single pipeline with nodes included
- `create` - Create new pipeline
- `update` - Update existing pipeline
- `destroy` - Delete pipeline (cascades to nodes)

Location: `app/controllers/v1/admin/video_production/pipelines_controller.rb`

### V1::Admin::VideoProduction::NodesController

Admin-only CRUD operations for nodes within a pipeline.

**Actions:**
- `index` - All nodes for a pipeline (ordered by created_at)
- `show` - Single node
- `create` - Create new node (validates inputs)
- `update` - Update node (validates inputs, resets status if needed)
- `destroy` - Delete node (cleans up references)

Location: `app/controllers/v1/admin/video_production/nodes_controller.rb`

**Error Responses:**
- `404 Not Found` - Pipeline or node not found
- `422 Unprocessable Entity` - Validation errors

## Serializers

### SerializeAdminVideoProductionPipeline

Serializes a pipeline with optional nodes.

```ruby
SerializeAdminVideoProductionPipeline.(
  pipeline,
  include_nodes: true
)
```

Location: `app/serializers/serialize_admin_video_production_pipeline.rb`

### SerializeAdminVideoProductionPipelines

Collection serializer for pipelines (delegates to singular).

Location: `app/serializers/serialize_admin_video_production_pipelines.rb`

### SerializeAdminVideoProductionNode

Serializes a single node with all fields.

```ruby
SerializeAdminVideoProductionNode.(node)
```

Location: `app/serializers/serialize_admin_video_production_node.rb`

### SerializeAdminVideoProductionNodes

Collection serializer for nodes (delegates to singular).

Location: `app/serializers/serialize_admin_video_production_nodes.rb`

## Routes

```ruby
namespace :v1 do
  namespace :admin do
    namespace :video_production do
      resources :pipelines, only: [:index, :show, :create, :update, :destroy], param: :uuid do
        resources :nodes, only: [:index, :show, :create, :update, :destroy], param: :uuid
      end
    end
  end
end
```

**Generated Routes:**
- `GET    /v1/admin/video_production/pipelines`
- `POST   /v1/admin/video_production/pipelines`
- `GET    /v1/admin/video_production/pipelines/:uuid`
- `PATCH  /v1/admin/video_production/pipelines/:uuid`
- `DELETE /v1/admin/video_production/pipelines/:uuid`
- `GET    /v1/admin/video_production/pipelines/:pipeline_uuid/nodes`
- `POST   /v1/admin/video_production/pipelines/:pipeline_uuid/nodes`
- `GET    /v1/admin/video_production/pipelines/:pipeline_uuid/nodes/:uuid`
- `PATCH  /v1/admin/video_production/pipelines/:pipeline_uuid/nodes/:uuid`
- `DELETE /v1/admin/video_production/pipelines/:pipeline_uuid/nodes/:uuid`

## Testing

### Model Tests

Location: `test/models/video_production/`
- `pipeline_test.rb` - 38 tests for Pipeline model
- `node_test.rb` - 38 tests for Node model

### Command Tests

Location: `test/commands/video_production/`
- `node/validate_inputs_test.rb` - 20 tests for input validation

### Controller Tests

Location: `test/controllers/v1/admin/video_production/`
- `pipelines_controller_test.rb` - 30 tests for pipeline CRUD
- `nodes_controller_test.rb` - 41 tests for node CRUD

**Total:** 167 tests covering Phase 1 and Phase 2

### Test Patterns

```ruby
# FactoryBot factories
pipeline = create(:video_production_pipeline)
node = create(:video_production_node, pipeline: pipeline)

# With traits
node = create(:video_production_node, :completed)
node = create(:video_production_node, :merge_videos)

# Controller authentication
guard_admin! :v1_admin_video_production_pipelines_path, method: :get

# Error testing
assert_raises(VideoProductionBadInputsError) do
  VideoProduction::Node::ValidateInputs.('asset', { 'foo' => ['bar'] }, pipeline.id)
end
```

## Execution System

### Executors

Node executors are Sidekiq jobs that process individual nodes. Each executor handles a specific node type.

Location: `app/commands/video_production/node/executors/`

**Implemented Executors:**
- `MergeVideos` - Concatenates videos via Lambda (FFmpeg)
- `GenerateVoiceover` - Text-to-speech via ElevenLabs API

**Future Executors:**
- `TalkingHead` - HeyGen talking head videos
- `GenerateAnimation` - Veo 3 / Runway animations
- `RenderCode` - Remotion code screen animations
- `MixAudio` - FFmpeg audio replacement via Lambda
- `ComposeVideo` - FFmpeg picture-in-picture via Lambda

### Lambda Integration

The `VideoProduction::InvokeLambda` command provides a reusable interface for calling AWS Lambda functions:

```ruby
result = VideoProduction::InvokeLambda.(
  'jiki-video-merger-production',
  {
    input_videos: ['s3://bucket/video1.mp4', 's3://bucket/video2.mp4'],
    output_bucket: 'jiki-videos',
    output_key: 'pipelines/123/nodes/456/output.mp4'
  }
)
# Returns: { s3_key:, duration:, size:, statusCode: 200 }
```

Location: `app/commands/video_production/invoke_lambda.rb`

**Lambda Functions:**
- **video-merger**: FFmpeg concatenation (Node.js 20, 3008 MB, 15 min timeout)

See `services/video_production/README.md` for Lambda deployment.

### External API Integration

External APIs (ElevenLabs, HeyGen, Veo 3) use a two-command pattern: **submit + poll**.

#### ElevenLabs Pattern

**Commands:**
- `VideoProduction::APIs::ElevenLabs::GenerateAudio` - Submit TTS job
- `VideoProduction::APIs::ElevenLabs::CheckForResult` - Poll for completion

Location: `app/commands/video_production/apis/eleven_labs/`

**Flow:**
1. Executor calls `GenerateAudio`
2. `GenerateAudio` submits to API, stores `audio_id` in node metadata
3. `GenerateAudio` queues `CheckForResult` for 10 seconds later
4. `CheckForResult` polls every 10 seconds (max 60 attempts = 10 minutes)
5. When complete, downloads audio from ElevenLabs and uploads to S3
6. Updates node status to `completed` with S3 key in output

**Self-Rescheduling Pattern:**
```ruby
# CheckForResult reschedules itself if still processing
if status == 'processing'
  self.class.set(wait: 10.seconds).defer(pipeline_id, node_id, audio_id, attempt + 1)
end
```

**Future APIs:** HeyGen and Veo 3 will follow the same pattern.

### JSONB Partial Updates

All executor database updates use JSONB `jsonb_set()` to avoid race conditions between Next.js and Rails:

```ruby
sql = <<~SQL
  UPDATE video_production_nodes
  SET metadata = jsonb_set(COALESCE(metadata, '{}'::jsonb), '{key}', $1)
  WHERE pipeline_id = $2 AND id = $3
SQL

ActiveRecord::Base.connection.execute(
  ActiveRecord::Base.sanitize_sql([sql, value.to_json, pipeline_id, node_id])
)
```

This prevents data loss when Next.js updates structure fields (`config`) while Rails updates state fields (`metadata`, `output`).

## Common Patterns

### Creating a Pipeline with Nodes

```ruby
# 1. Create pipeline
pipeline = VideoProduction::Pipeline::Create.(
  title: "Course Intro",
  version: "1.0",
  config: {},
  metadata: {}
)

# 2. Create asset nodes
script = VideoProduction::Node::Create.(
  pipeline,
  title: "Script",
  type: "asset",
  asset: { source: "scripts/intro.txt", type: "text" }
)

# 3. Create processing nodes
talking_head = VideoProduction::Node::Create.(
  pipeline,
  title: "Talking Head",
  type: "talking-head",
  inputs: { script: [script.uuid] },
  config: { provider: "heygen", avatarId: "avatar-1" }
)
```

### Updating Node Structure

```ruby
# This will reset status to 'pending' because inputs changed
VideoProduction::Node::Update.(
  node,
  inputs: { segments: [new_uuid1, new_uuid2] }
)

# This will NOT reset status (only title changed)
VideoProduction::Node::Update.(
  node,
  title: "New Title"
)
```

### Deleting a Node with References

```ruby
# Node A references Node B in its inputs
node_a.inputs # => { "segments" => ["node-b-uuid", "node-c-uuid"] }

# Delete Node B
VideoProduction::Node::Destroy.(node_b)

# Node A's inputs are updated
node_a.reload.inputs # => { "segments" => ["node-c-uuid"] }
```

## Important Notes

1. **STI Prevention**: Use `self.inheritance_column = :_type_disabled` because we have a `type` column
2. **UUID Primary Keys**: Both tables use UUID primary keys for better distributed systems support
3. **Input Validation**: Always validate inputs when creating/updating nodes
4. **Status Management**: Status automatically resets to `pending` when structure changes
5. **Reference Cleanup**: Deleting a node automatically cleans up references in other nodes
6. **Shared Database**: Next.js and Rails share the database - follow column ownership rules
7. **Admin Only**: All endpoints require admin authentication

## Related Files

- `VIDEO_PRODUCTION_PLAN.md` - Complete implementation roadmap
- `tmp-video-production/README.md` - TypeScript reference code from Next.js
- `.context/architecture.md` - Rails patterns and Mandate usage
- `.context/controllers.md` - Controller patterns
- `.context/testing.md` - Testing guidelines
