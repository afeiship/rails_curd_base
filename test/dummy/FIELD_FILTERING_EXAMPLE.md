# RailsCurdBase 使用示例

## 基础示例

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  supports_query(
    pagination: { enabled: true, default_per: 10, max_per: 50 },
    sorting: { enabled: true, allowed_fields: [:id, :title, :created_at] },
    searching: { enabled: true, searchable_fields: [:title, :content] },
    filtering: { enabled: true, filterable_fields: [:status] }
  )

  # ✅ 配置 index 只返回部分字段（列表页不需要所有字段）
  index_fields :id, :title, :status, :created_at

  # ✅ 配置 show 返回完整字段（详情页需要所有信息）
  show_fields :id, :title, :content, :status, :published_at, :created_at, :updated_at

  # ✅ 生命周期钩子
  def before_create(resource)
    resource.author = current_user
    resource.published_at = Time.current if resource.status == 'published'
    true
  end
end
```

## 使用场景

### 场景 1：列表页精简字段

```ruby
class Api::UsersController < RailsCurdBase::CurdController
  supports_query(
    pagination: { enabled: true, default_per: 20 }
  )

  # 列表只返回基本信息
  index_fields :id, :username, :email, :role, :created_at

  # 详情返回完整信息
  show_fields :id, :username, :email, :role, :bio, :avatar_url, :created_at, :updated_at
end
```

**请求示例**：
```bash
# 列表请求 - 只返回配置的字段
GET /api/users
# 响应：[{id: 1, username: "john", email: "...", role: "admin", created_at: "..."}]

# 详情请求 - 返回完整字段
GET /api/users/1
# 响应：{id: 1, username: "john", email: "...", role: "admin", bio: "...", ...}
```

### 场景 2：动态指定字段（优先级最高）

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  supports_query(pagination: { enabled: true })

  # 配置默认字段
  index_fields :id, :title, :created_at
end
```

**请求示例**：
```bash
# 使用配置的字段
GET /api/posts
# 返回：id, title, created_at

# 动态指定字段（覆盖配置）
GET /api/posts?fields=id,title,status
# 返回：id, title, status

# 动态指定字段（show 也支持）
GET /api/posts/1?fields=id,title,content
# 返回：id, title, content
```

### 场景 3：完全自定义序列化

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  supports_query(pagination: { enabled: true })

  # 配置基础字段过滤
  index_fields :id, :title

  private

  # 完全自定义序列化逻辑（优先级高于字段配置）
  def serialize_resource(resource)
    {
      id: resource.id,
      title: resource.title,
      summary: resource.content.truncate(50),
      author: resource.author.username,
      created_at: resource.created_at.strftime("%Y-%m-%d")
    }
  end
end
```

### 场景 4：不同角色返回不同字段

```ruby
class Api::CommentsController < RailsCurdBase::CurdController
  # 公开字段
  index_fields :id, :content, :created_at

  private

  def serialize_resource(resource)
    data = resource.as_json

    # 管理员可以看到更多字段
    if current_user&.admin?
      data[:author_email] = resource.author.email
      data[:ip_address] = resource.ip_address
    end

    data
  end
end
```

## 字段过滤优先级

```
URL 参数 (?fields=xxx)
    ↓ 优先级最高
Action 配置 (index_fields/show_fields)
    ↓
全部字段 (as_json)
```

## 最佳实践

### 1. 性能优化

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  # 列表页只返回必要字段，减少数据传输
  index_fields :id, :title, :status, :created_at

  # 详情页返回完整数据
  show_fields :id, :title, :content, :status, :author_id, :created_at, :updated_at
end
```

### 2. 隐藏敏感信息

```ruby
class Api::UsersController < RailsCurdBase::CurdController
  # 列表不暴露敏感信息
  index_fields :id, :username, :avatar_url

  # 详情可以显示更多信息（但仍不包含密码）
  show_fields :id, :username, :email, :bio, :avatar_url
end
```

### 3. 灵活的客户端控制

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  supports_query(
    pagination: { enabled: true, default_per: 10 }
  )

  # 配置默认字段（客户端不传 ?fields 时使用）
  index_fields :id, :title, :created_at

  # 客户端可以动态指定需要的字段
  # GET /api/posts?fields=id,title,status
end
```

### 4. 关联数据优化

```ruby
class Api::CommentsController < RailsCurdBase::CurdController
  # 列表只返回作者 ID
  index_fields :id, :content, :author_id, :created_at

  # 详情返回完整关联数据
  show_fields :id, :content, :author_id, :post_id, :created_at, :updated_at
end
```

## API 响应示例

### Index 响应（字段过滤）

```bash
GET /api/posts
```

```json
{
  "success": true,
  "code": 200,
  "msg": "success",
  "data": {
    "rows": [
      {
        "id": 1,
        "title": "First Post",
        "status": "published",
        "created_at": "2025-02-14T06:25:42.914Z"
      }
    ],
    "total": 100
  }
}
```

### Show 响应（完整字段）

```bash
GET /api/posts/1
```

```json
{
  "success": true,
  "code": 200,
  "msg": "success",
  "data": {
    "id": 1,
    "title": "First Post",
    "content": "This is the first post content",
    "status": "published",
    "published_at": "2025-02-13T06:25:42.910Z",
    "created_at": "2025-02-14T06:25:42.914Z",
    "updated_at": "2025-02-14T06:25:42.914Z"
  }
}
```

### 动态字段响应

```bash
GET /api/posts?fields=id,title
```

```json
{
  "success": true,
  "code": 200,
  "msg": "success",
  "data": {
    "rows": [
      {
        "id": 1,
        "title": "First Post"
      }
    ],
    "total": 100
  }
}
```

## 与自定义序列化的关系

- **字段过滤** - 简单过滤现有字段（推荐用于简单场景）
- **自定义序列化** - 完全控制输出格式（推荐用于复杂场景）

两者可以结合使用：
```ruby
class Api::PostsController < RailsCurdBase::CurdController
  index_fields :id, :title, :created_at

  private

  def serialize_resource(resource)
    # 先自定义数据
    data = {
      id: resource.id,
      title: resource.title.upcase,  # 转大写
      summary: resource.content.truncate(50),
      created_at: resource.created_at
    }

    # 再根据字段配置过滤
    fields = requested_fields || fields_for_action(action)
    filter_fields(data, fields) if fields
    data
  end
end
```
