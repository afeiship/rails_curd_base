# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RailsCurdBase is a Rails Engine gem that provides a zero-configuration CRUD base controller for Rails API applications. It offers built-in pagination, sorting, searching, filtering, field selection, and lifecycle hooks.

**Technology Stack:**
- Ruby 2.7+
- Rails 6.0+ (API mode only, inherits from `ActionController::API`)
- Kaminari for pagination
- RailsWarp for unified JSON responses

## Common Development Commands

### Building and Testing

```bash
# Run the dummy app server
cd test/dummy && bin/rails server

# Run console in dummy app
cd test/dummy && bin/rails console

# Build the gem
npm run build
# or: gem build *.gemspec

# Run RuboCop
npm run rubocop
# or: bundle exec rubocop

# Clean build artifacts
npm run clean
```

### Testing the API

The dummy app at `test/dummy/` contains a working example:

```bash
# Start server
cd test/dummy && bin/rails server

# Test API (server must be running)
curl http://localhost:3000/api/posts
curl http://localhost:3000/api/posts/1
curl -X POST http://localhost:3000/api/posts -H 'Content-Type: application/json' -d '{"title":"Test"}'
```

See `test/dummy/rest_api.http` for complete API examples.

### Release

```bash
# Create a new release
npm run release
```

## Architecture

### Core Components

**CurdController** (`app/controllers/rails_curd_base/curd_controller.rb`)
- Main controller providing CRUD operations
- Inherits from `ActionController::API`
- Includes `Queryable` concern for query functionality
- Automatically derives resource class from controller name using `controller_name.singularize.classify.constantize`
- Derives resource key using `controller_name.singularize.underscore.to_sym`

**Queryable Concern** (`app/controllers/concerns/rails_curd_base/queryable.rb`)
- Configurable query module with class method `supports_query`
- Supports: pagination (Kaminari), sorting, searching, filtering
- Uses `apply_query_with_meta` to apply all query transformations
- All features are opt-in via configuration

**Field Filtering**
- Class methods `index_fields(*fields)` and `show_fields(*fields)` configure default fields
- URL parameter `?fields=id,title` can override configuration (highest priority)
- Field filtering is applied in `serialize_resource` before returning data
- Priority: URL params > action config > all fields (as_json)

### Resource Derivation

The controller automatically derives:
- `resource_class` - Model class from controller name (e.g., `Api::PostsController` → `Post`)
- `resource_key` - Parameter key (e.g., `:post`)
- `resource` - Instance variable (e.g., `@post`)

Override these methods in controllers if needed:
```ruby
def resource_class
  CustomModel  # Override auto-derivation
end
```

### Response Format

All responses use RailsWarp's unified format:
- **Success**: `ok data: {...}, code: 200` (message defaults to "success")
- **Error**: `fail message: "...", code: 422, data: { errors: [...] }`

**Note**: Success responses do NOT include custom messages - only error responses have messages.

### Lifecycle Hooks

Four hooks available (all return `true` to continue, `false` to abort):
- `before_create(resource)` - called before save on create
- `after_create(resource)` - called after successful create
- `before_update(resource)` - called before save on update
- `after_update(resource)` - called after successful update

`before_save` and `after_save` are also available and route to create/update hooks.

### Parameter Handling

The `resource_params` method supports both flat and nested formats:
- **Flat format** (recommended): `{"title": "...", "content": "..."}`
- **Nested format**: `{"post": {"title": "...", "content": "..."}}`

This is controlled by checking if `params.key?(resource_key)` - if present, uses nested format, otherwise uses flat format with `permit!`.

### Serialization Override Points

To customize serialization, override these methods:
```ruby
def serialize_resource(resource)
  # Custom single resource serialization
  { id: resource.id, title: resource.title.upcase }
end

def serialize_collection(collection)
  # Custom collection serialization
  collection.map { |r| serialize_resource(r) }
end
```

### Query Configuration

`supports_query` accepts a hash with four top-level keys:
- `pagination` - `{ enabled:, default_per:, max_per:, page_param:, per_param: }`
- `sorting` - `{ enabled:, allowed_fields:, sort_param:, default_direction: }`
- `searching` - `{ enabled:, searchable_fields:, search_param: }`
- `filtering` - `{ enabled:, filterable_fields:, filter_param: }`

Filter operators: `eq` (default), `neq`, `gt`, `gte`, `lt`, `lte`, `in`, `nin`

### Customization Points (in order of precedence)

1. **Override `collection`** - Scope data (e.g., `current_user.posts`)
2. **Override `serialize_resource/serialize_collection`** - Custom serialization
3. **Override `before_create/after_create/before_update/after_update`** - Add callbacks
4. **Override `resource_class/resource_key`** - Change resource derivation

## Important Implementation Details

### Query Execution Order

When `index` is called:
1. `collection` method called (override to scope data)
2. `apply_query_with_meta` applies query transformations:
   - Filtering → Searching → Sorting → Count total → Pagination
3. `serialize_collection` serializes each resource
4. Field filtering applied (if configured)

### Field Filtering Implementation

Field filtering happens in `serialize_resource`:
1. Get data via `resource.as_json`
2. Determine fields: URL params > action config > nil (all fields)
3. Call `filter_fields(data, fields)` which uses `select!` to filter keys

**Important**: If you override `serialize_resource`, field filtering still applies to your custom data unless you call it differently.

### Controller Naming Convention

Controllers should follow Rails REST conventions:
- `Api::PostsController` → uses `Post` model, `:post` param, `@post` instance
- `Api::UsersController` → uses `User` model, `:user` param, `@user` instance

The derivation logic: `controller_name.singularize.classify.constantize`

### Error Handling

- `set_resource` catches `ActiveRecord::RecordNotFound` and returns 404
- Validation errors return 422 with `errors.full_messages`
- Success responses return appropriate codes (200, 201, 204)

## File Structure

```
app/controllers/rails_curd_base/
  curd_controller.rb          # Main CRUD controller (126 lines)
  application_controller.rb   # Base controller (empty, 5 lines)

app/controllers/concerns/rails_curd_base/
  queryable.rb                # Query functionality concern (182 lines)

lib/rails_curd_base/
  engine.rb                   # Rails Engine definition
  version.rb                  # Gem version (currently 0.1.3)
```

## Dependencies

Required runtime dependencies (see gemspec):
- `rails >= 6.0`
- `kaminari >= 0.16` - pagination
- `rails_warp >= 0.1.0` - unified JSON responses

These are required in `lib/rails_curd_base.rb` before the engine loads.
