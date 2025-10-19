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
- **Rails writes**: `status`, `metadata`, `output`, `is_valid`, `validation_errors`

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

  # Validation state (Rails writes)
  t.boolean :is_valid, null: false, default: false
  t.jsonb :validation_errors, null: false, default: {}

  t.timestamps
end
```

**Node Types:**
- `asset` - Static file references
- `generate-talking-head` - HeyGen talking head videos
- `generate-animation` - Veo 3 / Runway animations
- `generate-voiceover` - ElevenLabs text-to-speech
- `render-code` - Remotion code screen animations
- `mix-audio` - FFmpeg audio replacement
- `merge-videos` - FFmpeg video concatenation
- `compose-video` - FFmpeg picture-in-picture overlays

**Status Values:** `pending`, `in_progress`, `completed`, `failed`

## Models

### VideoProduction::Pipeline (`app/models/video_production/pipeline.rb`)

- Has many nodes (cascade delete)
- Auto-generates UUID on create
- JSONB accessors: `storage`, `working_directory`, `total_cost`, `estimated_total_cost`, `progress`
- `progress_summary` method returns node progress counts from metadata

### VideoProduction::Node (`app/models/video_production/node.rb`)

- Uses `disable_sti!` to prevent Rails STI on `type` column
- Belongs to pipeline
- Auto-generates UUID on create
- JSONB accessors for config (provider), metadata (process_uuid, timestamps, error, cost), output (s3_key, duration, size)
- Scopes: `pending`, `in_progress`, `completed`, `failed`
- `inputs_satisfied?` - Checks if all input nodes are completed
- `ready_to_execute?` - Returns true if pending, valid, and inputs satisfied

## Schema-Based Validation

Each node type has a schema class in `app/commands/video_production/node/schemas/` that defines:
- **INPUTS** - Input slot definitions (types, requirements, constraints)
- **CONFIG** - Configuration field definitions (types, allowed values, requirements)

**Schema Structure:**
- Input types: `:single` (one node reference) or `:multiple` (array of references with min/max counts)
- Config types: `:string`, `:integer`, `:boolean`, `:array`, `:hash`
- Common properties: `required`, `allowed_values`, `description`, `min_count`, `max_count`

**Validation Commands:**
- `VideoProduction::Node::Validate` - Main orchestrator that calls ValidateInputs and ValidateConfig, updates `is_valid` and `validation_errors` columns
- `VideoProduction::Node::ValidateInputs` - Validates input slots against schema, checks node references exist
- `VideoProduction::Node::ValidateConfig` - Validates config fields against schema, checks types and allowed values

Validation runs automatically on node create/update. Nodes with `is_valid: false` cannot execute (`ready_to_execute?` checks this).

## Commands

All commands in `app/commands/video_production/` use the Mandate pattern (see `.context/architecture.md`).

**Pipeline CRUD:**
- `Pipeline::Create` - Creates pipeline with title, version, config, metadata
- `Pipeline::Update` - Updates pipeline attributes
- `Pipeline::Destroy` - Deletes pipeline (cascades to nodes)

**Node CRUD:**
- `Node::Create` - Creates node and runs validation (raises `VideoProductionBadInputsError` on failure)
- `Node::Update` - Updates node, resets status to `pending` if structure fields (`inputs`, `config`, `asset`) change
- `Node::Destroy` - Deletes node and cleans up references (removes UUID from array inputs, removes entire slot for single inputs)

## Controllers & Serializers

**Controllers:** Admin-only CRUD at `/v1/admin/video_production/*` (see Routes below)
- `PipelinesController` - Index (paginated 25/page), show, create, update, destroy
- `NodesController` - Nested under pipelines, index, show, create (validates), update (validates, resets status), destroy (cleans refs)
- Returns 404 for not found, 422 for validation errors

**Serializers:** All in `app/serializers/` using Mandate pattern
- `SerializeAdminVideoProductionPipeline(s)` - Pipeline with UUID, title, version, config, metadata (optionally includes nodes)
- `SerializeAdminVideoProductionNode(s)` - Node with all fields including validation state

## Routes

Nested resources under `/v1/admin/video_production/`:
- `pipelines` - Standard REST actions (index, show, create, update, destroy) using `:uuid` param
- `pipelines/:pipeline_uuid/nodes` - Nested nodes with same REST actions using `:uuid` param

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

### Execution Lifecycle Commands

All execution commands follow a strict lifecycle to prevent race conditions and ensure data integrity.

**Execution Lifecycle:**
1. `ExecutionStarted` - Marks node as `in_progress`, generates unique `process_uuid`
2. `ExecutionUpdated` - Updates metadata during processing (with UUID verification)
3. `ExecutionSucceeded` or `ExecutionFailed` - Completes execution (with UUID verification)

**Execution Lifecycle Commands** (`app/commands/video_production/node/`):

1. `ExecutionStarted` - Sets status to `in_progress`, generates unique `process_uuid`, sets `started_at`, returns UUID for tracking
2. `ExecutionUpdated` - Updates metadata during processing (verifies process_uuid matches, silently exits on mismatch)
3. `ExecutionSucceeded` - Sets status to `completed`, stores output, sets `completed_at` (verifies process_uuid)
4. `ExecutionFailed` - Sets status to `failed`, stores error message, sets `completed_at` (verifies process_uuid, accepts nil for pre-execution failures)

All use `with_lock` for atomicity. UUID verification prevents stale jobs from corrupting state.

### Race Condition Protection

The execution system implements comprehensive protection against three types of race conditions:

**1. Webhook Double-Processing**
- Problem: Webhook arrives before/during polling job
- Solution: `CheckForResult` verifies status is still `in_progress` before processing

**2. Concurrent Executions**
- Problem: Second execution starts while first is still running
- Solution: Each execution has unique `process_uuid`; all completion commands verify UUID matches

**3. Check-Then-Update Races**
- Problem: Status/UUID read and write not atomic
- Solution: All commands use `node.with_lock` to make read-check-write operations atomic

**Stale Job Behavior:**
- When UUID mismatch detected, commands silently exit
- No errors raised (normal distributed systems behavior)
- Current execution continues unaffected

### Executors

Node executors are Sidekiq jobs that process individual nodes. Each executor handles a specific node type and follows the execution lifecycle.

Location: `app/commands/video_production/node/executors/`

**Implemented Executors:**
- `MergeVideos` - Concatenates videos via Lambda (FFmpeg)
- `GenerateVoiceover` - Text-to-speech via ElevenLabs API
- `GenerateTalkingHead` - Talking head videos via HeyGen API

**Executor Pattern:** Sidekiq jobs that (1) call ExecutionStarted to get process_uuid, (2) perform work (Lambda/API calls), (3) call ExecutionSucceeded with output, or ExecutionFailed on error.

**Future Executors:**
- `GenerateAnimation` - Veo 3 / Runway animations
- `RenderCode` - Remotion code screen animations
- `MixAudio` - FFmpeg audio replacement via Lambda
- `ComposeVideo` - FFmpeg picture-in-picture via Lambda

### Lambda Integration

`VideoProduction::InvokeLambda` - Synchronous Lambda invocation wrapper. Currently used by MergeVideos executor.

**Lambda Functions:** `video-merger` for FFmpeg video concatenation (Node.js 20, 3008 MB, 15 min timeout). See `services/video_production/README.md` for deployment.

### External API Integration

External APIs use a **three-command pattern** (submit → poll → process) with inheritance from `CheckForResult` base class.

**Pattern:**
1. **Generate** command submits job to API, updates metadata with external job ID, queues CheckForResult polling
2. **CheckForResult** polls API status (60 max attempts, 10s interval), verifies process_uuid matches before processing, self-reschedules until complete/failed
3. **ProcessResult** downloads output, uploads to S3, marks execution succeeded

**Implemented:**
- **ElevenLabs** (`app/commands/video_production/apis/eleven_labs/`) - Text-to-speech via `POST /text-to-speech/{voice_id}`
- **HeyGen** (`app/commands/video_production/apis/heygen/`) - Talking head videos via `POST /v2/video/generate`, uses presigned URLs for audio/background inputs

**Future:** Veo 3 will follow same pattern.

### Node Metadata Fields

**Process Tracking:**
- `process_uuid` - Unique identifier for this execution (prevents race conditions)
- `started_at` - ISO8601 timestamp when execution started
- `completed_at` - ISO8601 timestamp when execution finished

**External API Integration:**
- `audio_id` - ElevenLabs job ID
- `video_id` - HeyGen job ID
- `stage` - Current processing stage (e.g., 'submitted', 'processing')
- `job_id` - Generic external job identifier

**Error Tracking:**
- `error` - Error message if execution failed

**Other:**
- `cost` - Estimated cost for this execution
- `retries` - Number of retry attempts

### Database Concurrency

**Process UUID Protection:**
All execution commands verify `process_uuid` matches before updating. Combined with `with_lock`, this ensures:
- Only the current execution can update the node
- Stale jobs (from webhooks or superseded executions) silently exit
- No data corruption from concurrent execution attempts

**Next.js/Rails Coordination:**
Column ownership prevents conflicts:
- **Next.js writes**: `type`, `inputs`, `config`, `asset`, `title`
- **Rails writes**: `status`, `metadata`, `output`, `is_valid`, `validation_errors`

Both systems can safely write to their columns simultaneously without conflicts.

## Key Architecture Points

1. **STI Prevention**: Models use `disable_sti!` to allow `type` column without Rails STI
2. **UUID Primary Keys**: Both tables use UUIDs for distributed systems support
3. **Validation**: Runs automatically on create/update, stores results in `is_valid`/`validation_errors` columns
4. **Status Management**: Automatically resets to `pending` when structure fields (`inputs`, `config`, `asset`) change
5. **Reference Cleanup**: Deleting node removes its UUID from other nodes' input arrays
6. **Shared Database**: Next.js (writes structure) and Rails (writes execution state/validation) have distinct column ownership
7. **Race Condition Protection**: process_uuid tracking + database locks prevent concurrent execution conflicts
8. **Admin Only**: All API endpoints require admin authentication

## Related Files

- `VIDEO_PRODUCTION_PLAN.md` - Complete implementation roadmap
- `tmp-video-production/README.md` - TypeScript reference code from Next.js
- `.context/architecture.md` - Rails patterns and Mandate usage
- `.context/controllers.md` - Controller patterns
- `.context/testing.md` - Testing guidelines
