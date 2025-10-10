# Admin Section Implementation Plan

## Overview
Add an admin section to the API at `v1/admin/...` with CRUD operations for email templates, protected by admin-only authorization.

## Implementation Steps

### 1. Database Schema Changes

#### Update EmailTemplate Migration
- [ ] Open the original `email_templates` migration file
- [ ] Rename `key` column to `slug`
- [ ] Rename `template_type` column to `type`
- [ ] Update unique index to: `index_email_templates_on_type_and_slug_and_locale`
- [ ] Run `bin/rails db:reset` to recreate database from schema

#### Update Users Migration
- [ ] Open the original `users` migration file
- [ ] Add `admin` boolean column (default: false, null: false)
- [ ] This will be applied during the `db:reset`

### 2. EmailTemplate Model Updates

- [ ] Add `disable_sti!` at the top of the class to prevent Rails STI behavior on `type` column
- [ ] Update `enum :template_type` to `enum :type`
- [ ] Update validation from `template_type` to `type`
- [ ] Update uniqueness validation scope from `template_type` to `type` and `key` to `slug`
- [ ] Update `find_for` method to use `type` and `slug` parameters
- [ ] Update `for_level_completion` scope to use `type` and `slug`
- [ ] Update `find_for_level_completion` method

### 3. Update EmailTemplate Factory

- [ ] Change `template_type` to `type`
- [ ] Change `key` to `slug`
- [ ] Verify trait works with new column names

### 4. Update User Factory

- [ ] Add `:admin` trait that sets `admin: true`

### 5. Update Existing Code References

- [ ] Search for all references to `email_template.template_type` and change to `.type`
- [ ] Search for all references to `email_template.key` and change to `.slug`
- [ ] Update mailer code (`app/mailers/`) that uses EmailTemplate
- [ ] Update any job code that uses EmailTemplate
- [ ] Run tests to verify nothing breaks

### 6. Admin Base Controller

- [ ] Create `app/controllers/v1/admin/base_controller.rb`
- [ ] Inherit from `ApplicationController` (gets authentication from parent)
- [ ] Add `before_action :ensure_admin!`
- [ ] Implement `ensure_admin!` private method:
  - Check `current_user.admin?`
  - Return 403 Forbidden with error JSON if not admin:
    ```ruby
    {
      error: {
        type: "forbidden",
        message: "Admin access required"
      }
    }
    ```

### 7. EmailTemplate::Update Command

- [ ] Create `app/commands/email_template/update.rb`
- [ ] Use Mandate pattern: `initialize_with :email_template, :params`
- [ ] Implement `call` method:
  - Filter params to only allow: `subject`, `body_mjml`, `body_text`
  - Call `email_template.update!` with filtered params
  - Return the updated email_template
- [ ] Add validation in memoized methods:
  - Validate presence of subject, body_mjml, body_text if provided
  - Raise `ValidationError` with errors hash if invalid

### 8. Admin Email Templates Controller

- [ ] Create `app/controllers/v1/admin/email_templates_controller.rb`
- [ ] Inherit from `V1::Admin::BaseController`
- [ ] Implement `index` action:
  - Fetch all email templates
  - Render JSON: `{ email_templates: SerializeEmailTemplates.(EmailTemplate.all) }`
- [ ] Implement `show` action:
  - Find email template by ID
  - Render JSON: `{ email_template: SerializeEmailTemplate.(@email_template) }`
  - Return 404 if not found
- [ ] Implement `update` action:
  - Find email template by ID
  - Call `EmailTemplate::Update.(@email_template, email_template_params)`
  - Render JSON: `{ email_template: SerializeEmailTemplate.(email_template) }`
  - Rescue `ValidationError` and return 400 with errors
  - Return 404 if not found
- [ ] Implement `destroy` action:
  - Find email template by ID
  - Call `@email_template.destroy!`
  - Return 204 No Content
  - Return 404 if not found
- [ ] Add private `email_template_params` method permitting: subject, body_mjml, body_text
- [ ] Add before_action to find email template for show/update/destroy

### 9. Serializers

#### SerializeEmailTemplate (singular)
- [ ] Create `app/serializers/serialize_email_template.rb`
- [ ] Use Mandate pattern: `initialize_with :email_template`
- [ ] Return hash with:
  - `id`
  - `type` (from email_template.type enum)
  - `slug`
  - `locale`
  - `subject`
  - `body_mjml`
  - `body_text`

#### SerializeEmailTemplates (plural)
- [ ] Create `app/serializers/serialize_email_templates.rb`
- [ ] Use Mandate pattern: `initialize_with :email_templates`
- [ ] Return array mapping each template to hash with:
  - `id`
  - `type`
  - `slug`
  - `locale`

### 10. Routes

- [ ] Update `config/routes.rb`
- [ ] Inside `namespace :v1` block, add:
  ```ruby
  namespace :admin do
    resources :email_templates, only: [:index, :show, :update, :destroy]
  end
  ```

### 11. Tests

#### Command Tests
- [ ] Create `test/commands/email_template/update_test.rb`
- [ ] Test successful update with all valid params
- [ ] Test updating subject only
- [ ] Test updating body_mjml only
- [ ] Test updating body_text only
- [ ] Test raises ValidationError with blank subject
- [ ] Test raises ValidationError with blank body_mjml
- [ ] Test raises ValidationError with blank body_text
- [ ] Test that type cannot be updated (filtered out)
- [ ] Test that slug cannot be updated (filtered out)
- [ ] Test that locale cannot be updated (filtered out)

#### Base Controller Tests
- [ ] Create `test/controllers/v1/admin/base_controller_test.rb`
- [ ] Create a test controller that inherits from Admin::BaseController
- [ ] Test that non-authenticated users receive 401
- [ ] Test that authenticated non-admin users receive 403
- [ ] Test that authenticated admin users can access

#### Email Templates Controller Tests
- [ ] Create `test/controllers/v1/admin/email_templates_controller_test.rb`
- [ ] Use `guard_incorrect_token!` macro for authentication tests:
  - `guard_incorrect_token! :v1_admin_email_templates_path, method: :get`
  - `guard_incorrect_token! :v1_admin_email_template_path, args: [1], method: :get`
  - `guard_incorrect_token! :v1_admin_email_template_path, args: [1], method: :patch`
  - `guard_incorrect_token! :v1_admin_email_template_path, args: [1], method: :delete`
- [ ] Test `GET index` returns 403 for non-admin users
- [ ] Test `GET index` returns all templates using SerializeEmailTemplates
- [ ] Test `GET index` returns empty array when no templates exist
- [ ] Test `GET show` returns 403 for non-admin users
- [ ] Test `GET show` returns single template with full data using SerializeEmailTemplate
- [ ] Test `GET show` returns 404 for non-existent template
- [ ] Test `PATCH update` returns 403 for non-admin users
- [ ] Test `PATCH update` calls EmailTemplate::Update command with correct params
- [ ] Test `PATCH update` returns updated template
- [ ] Test `PATCH update` handles ValidationError from command (returns 400)
- [ ] Test `PATCH update` returns 404 for non-existent template
- [ ] Test `DELETE destroy` returns 403 for non-admin users
- [ ] Test `DELETE destroy` deletes template successfully (returns 204)
- [ ] Test `DELETE destroy` returns 404 for non-existent template

#### Serializer Tests
- [ ] Create `test/serializers/serialize_email_template_test.rb`
- [ ] Test serializes all fields correctly (id, type, slug, locale, subject, body_mjml, body_text)
- [ ] Test with different template types

- [ ] Create `test/serializers/serialize_email_templates_test.rb`
- [ ] Test serializes collection with limited fields (id, type, slug, locale)
- [ ] Test empty collection returns empty array
- [ ] Test multiple templates

### 12. Update Context Documentation

- [ ] Update `.context/controllers.md`:
  - Add section on admin controllers and authorization pattern
  - Document `Admin::BaseController` pattern
  - Explain difference between authentication (ApplicationController) and authorization (Admin::BaseController)
  - Add example of admin controller

## Key Decisions

- **STI Disabling**: Use `disable_sti!` method (defined in initializer) to allow `type` column without Rails STI
- **Column Naming**: Using `slug` and `type` for consistency with rest of API
- **Immutable Fields**: `type`, `slug`, and `locale` cannot be updated via API (unique constraint)
- **Command Pattern**: All updates go through `EmailTemplate::Update` command
- **Database Reset**: Modify original migrations and run `db:reset` instead of new migrations
- **Authorization**: Separate concern from authentication - admin check happens in `Admin::BaseController`

## Before Committing

- [ ] Run `bin/rails test` - all tests must pass
- [ ] Run `bin/rubocop` - no linting errors
- [ ] Run `bin/brakeman` - no security issues
