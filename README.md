# RailsCurdBase

> RailsCurdBase 是一个用于 Ruby on Rails 的 CRUD 基础控制器 gem，提供开箱即用的增删改查功能、查询能力、分页、排序、搜索和过滤。它使用 RailsWarp 提供统一的 JSON 响应格式，并使用 Kaminari 处理分页。

## 特性

- 🔥 **零配置 CRUD** - 继承 `CurdController` 即可获取完整的增删改查功能
- 🔍 **强大查询** - 内置分页、排序、搜索、过滤功能，通过 `supports_query` 轻松配置
- 📦 **统一响应** - 基于 RailsWarp 的统一 JSON 响应格式
- 🎣 **生命周期钩子** - 提供 `before_create`, `after_create`, `before_update`, `after_update` 四个钩子
- 🤖 **AI 友助** - 配备完整的 LLM 提示文档 (`llms.txt`)，方便 AI 辅助编程
- ⚙️ **零依赖蓝图** - 不依赖任何序列化 gem，使用 Rails 原生 `as_json`
- 🔧 **高度可定制** - 轻松覆盖 `collection`、序列化方法等实现自定义逻辑

## 兼容性

- ✅ Rails 6.0+
- ✅ Ruby 2.7+
- ✅ API 模式 (`ActionController::API`)

## 安装

将这行添加到你的应用的 Gemfile 中：

```ruby
gem "rails_curd_base"
```

然后执行：

```bash
$ bundle install
```

或者手动安装：

```bash
$ gem install rails_curd_base
```

## 快速开始

### 1. 创建模型

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true
end
```

### 2. 创建控制器

```ruby
# app/controllers/api/posts_controller.rb
class Api::PostsController < RailsCurdBase::CurdController
  # 启用查询功能
  supports_query(
    pagination: { enabled: true, default_per: 10, max_per: 50 },
    sorting: { enabled: true, allowed_fields: [:id, :title, :created_at] },
    searching: { enabled: true, searchable_fields: [:title, :content] },
    filtering: { enabled: true, filterable_fields: [:status] }
  )
end
```

### 3. 配置路由

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    resources :posts
  end
end
```

就这么简单！现在你拥有了完整的 CRUD API：

- `GET /api/posts` - 列表（支持分页、排序、搜索、过滤）
- `GET /api/posts/1` - 详情
- `POST /api/posts` - 创建
- `PUT /api/posts/1` - 更新
- `DELETE /api/posts/1` - 删除

## API 使用示例

### 获取列表（基础）

```bash
GET /api/posts
```

**响应：**
```json
{
  "success": true,
  "code": 200,
  "msg": "Retrieved successfully",
  "data": {
    "rows": [...],
    "total": 100
  }
}
```

### 分页查询

```bash
GET /api/posts?page=1&size=20
```

### 排序

```bash
# 升序
GET /api/posts?sort=title

# 降序（使用 - 前缀）
GET /api/posts?sort=-created_at
```

### 搜索

```bash
GET /api/posts?q=hello
```

在 `title` 和 `content` 字段中模糊搜索 "hello"。

### 过滤

```bash
# 等于
GET /api/posts?filter[status]=published

# 大于等于
GET /api/posts?filter[views][gte]=100

# 在数组中
GET /api/posts?filter[category_id][in]=1,2,3
```

支持的过滤操作符：`eq`（默认）, `neq`, `gt`, `gte`, `lt`, `lte`, `in`, `nin`

### 组合查询

```bash
GET /api/posts?page=1&size=20&sort=-created_at&q=rails&filter[status]=published
```

### 创建记录

```bash
POST /api/posts
Content-Type: application/json

{
  "post": {
    "title": "Hello World",
    "content": "My first post",
    "status": "published"
  }
}
```

### 更新记录

```bash
PUT /api/posts/1
Content-Type: application/json

{
  "post": {
    "title": "Updated Title"
  }
}
```

### 删除记录

```bash
DELETE /api/posts/1
```

## 高级用法

### 自定义数据范围
```ruby
class Api::PostsController < RailsCurdBase::CurdController
  # 只返回当前用户的文章
  def collection
    current_user.posts
  end
end
```

### 字段过滤

**配置不同 action 返回不同字段**：
```ruby
class Api::PostsController < RailsCurdBase::CurdController
  # index 只返回部分字段
  index_fields :id, :title, :created_at

  # show 返回完整字段
  show_fields :id, :title, :content, :status, :created_at, :updated_at
end
```

**动态指定返回字段（通过 URL 参数）**：
```bash
# 只返回 id 和 title
GET /api/posts?fields=id,title

# 只返回 id, title, created_at
GET /api/posts/1?fields=id,title,created_at
```

**优先级**：URL 参数 > Action 配置 > 全部字段

### 生命周期钩子

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  supports_query(
    pagination: { enabled: true, default_per: 10 }
  )

  # 创建前钩子
  def before_create(resource)
    resource.author = current_user
    resource.published_at = Time.current if resource.status == 'published'
    true  # 必须返回 true，否则会中止保存
  end

  # 创建后钩子
  def after_create(resource)
    NotificationService.notify_followers(resource)
  end

  # 更新前钩子
  def before_update(resource)
    resource.editor = current_user
    true
  end

  # 更新后钩子
  def after_update(resource)
    CacheService.invalidate(resource)
  end
end
```

### 嵌套资源

```ruby
class Api::UserPostsController < RailsCurdBase::CurdController
  def collection
    user.posts  # 假设 params[:user_id] 存在
  end
end
```

### 完全自定义序列化

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  private

  def serialize_resource(resource)
    {
      id: resource.id,
      title: resource.title,
      summary: resource.content.truncate(100),
      author_name: resource.author.name,
      created_at: resource.created_at.iso8601
    }
  end

  def serialize_collection(collection)
    collection.map { |resource| serialize_resource(resource) }
  end
end
```

### 添加认证和授权

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  before_action :authenticate_user!
  before_action :set_post, only: [:show, :update, :destroy]

  private

  def authenticate_user!
    head :unauthorized unless current_user
  end

  def set_post
    @post = current_user.posts.find_by(id: params[:id])
  end
end
```

## Queryable 配置详解

`supports_query` 方法接受四个配置项：

### 分页配置

```ruby
pagination: {
  enabled: true,              # 是否启用
  default_per: 20,             # 默认每页数量
  max_per: 100,                # 最大每页数量
  page_param: :page,            # 页码参数名
  per_param: :size              # 每页数量参数名
}
```

### 排序配置

```ruby
sorting: {
  enabled: true,                    # 是否启用
  allowed_fields: [:id, :title],      # 允许排序的字段
  sort_param: :sort,                # 排序参数名
  default_direction: :asc            # 默认排序方向
}
```

使用：`?sort=title`（升序）或 `?sort=-title`（降序）

### 搜索配置

```ruby
searching: {
  enabled: true,                      # 是否启用
  searchable_fields: [:title, :content],  # 可搜索的字段
  search_param: :q                     # 搜索参数名
}
```

搜索会对所有 `searchable_fields` 执行 `LIKE %term%` 查询。

### 过滤配置

```ruby
filtering: {
  enabled: true,                        # 是否启用
  filterable_fields: [:status, :category_id],  # 可过滤的字段
  filter_param: :filter                 # 过滤参数名
}
```

支持的过滤操作符：
- `?filter[field]=value` - 等于 (eq)
- `?filter[field][neq]=value` - 不等于 (neq)
- `?filter[field][gt]=value` - 大于 (gt)
- `?filter[field][gte]=value` - 大于等于 (gte)
- `?filter[field][lt]=value` - 小于 (lt)
- `?filter[field][lte]=value` - 小于等于 (lte)
- `?filter[field][in]=1,2,3` - 在数组中 (in)
- `?filter[field][nin]=1,2,3` - 不在数组中 (nin)

## 资源自推导

`CurdController` 会自动从控制器名称推导资源类：

| 控制器 | 资源类 | 参数键 | 实例变量 |
|---------|---------|---------|-----------|
| `Api::PostsController` | `Post` | `:post` | `@post` |
| `Api::UsersController` | `User` | `:user` | `@user` |
| `Api::CommentsController` | `Comment` | `:comment` | `@comment` |

如需自定义，可覆盖以下方法：

```ruby
def resource_class
  CustomPost  # 覆盖自动推导
end

def resource_key
  :article  # 覆盖 :post
end
```

## 响应格式

所有 API 响应都遵循统一的格式（基于 RailsWarp）：

### 成功响应

```json
{
  "success": true,
  "code": 200,
  "msg": "Retrieved successfully",
  "data": { ... }
}
```

### 错误响应

```json
{
  "success": false,
  "code": 422,
  "msg": "Validation failed",
  "data": {
    "errors": ["Title can't be blank"]
  }
}
```

### HTTP 状态码

| 场景 | 状态码 |
|------|---------|
| 获取列表 | 200 |
| 获取详情 | 200 |
| 创建成功 | 201 |
| 更新成功 | 200 |
| 删除成功 | 204 |
| 验证失败 | 422 |
| 未找到 | 404 |
| 未授权 | 401 |

## 示例应用

完整的示例应用请查看 `test/dummy/` 目录：

```bash
cd test/dummy
bin/rails db:migrate
bin/rails db:seed
bin/rails server
```

然后访问 `http://localhost:3000/api/posts`

详细文档请查看 [test/dummy/EXAMPLE_USAGE.md](test/dummy/EXAMPLE_USAGE.md)

## AI 辅助编程

本项目包含完整的 LLM 提示文档 `llms.txt`，帮助 Claude、ChatGPT 等 AI 更好地理解和使用本项目。

## 依赖项

- **rails** >= 6.0
- **kaminari** >= 0.16 - 分页功能
- **rails_warp** >= 0.1.0 - 统一响应格式

## 性能优化建议

1. **数据库索引** - 在排序和过滤的字段上添加索引
   ```ruby
   add_index :posts, :status
   add_index :posts, :created_at
   add_index :posts, :author_id
   ```

2. **限制查询字段** - 通过覆盖 `serialize_resource` 只返回需要的字段

3. **使用缓存** - 在钩子方法中实现缓存逻辑

4. **优化 SQL** - 覆盖 `collection` 方法优化复杂查询

## 常见问题

### 1. 如何添加额外的查询逻辑？

```ruby
def collection
  base = super
  base = base.where(published: true) unless current_user&.admin?
  base
end
```

### 2. 如何实现软删除？

```ruby
def destroy
  resource.update!(deleted_at: Time.current)
  ok message: "Deleted successfully", code: 204
end
```

### 3. 如何添加版本控制？

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :posts
  end
end

# app/controllers/api/v1/posts_controller.rb
module Api
  module V1
    class PostsController < RailsCurdBase::CurdController
      # ...
    end
  end
end
```

### 4. 如何自定义错误处理？

```ruby
rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
rescue_from StandardError, with: :handle_error

private

def handle_not_found
  fail message: "Record not found", code: 404
end

def handle_error(e)
  Rails.logger.error "Error: #{e.class} - #{e.message}"
  fail message: "Internal server error", code: 500
end
```

## 开发

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b my-amazing-feature`)
3. 提交你的修改 (`git commit -am 'Add some amazing feature'`)
4. 推送到分支 (`git push origin my-amazing-feature`)
5. 创建新的 Pull Request

### 运行测试

```bash
cd test/dummy
bin/rails db:migrate RAILS_ENV=test
bin/rails test
```

## 路线图

![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)
![Rails](https://img.shields.io/badge/rails-%3E%206.0-red.svg)
![Ruby](https://img.shields.io/badge/ruby-%3E%3D2.7-red.svg)

## 作者

- **aric.zheng** - 1290657123@qq.com

## 许可证

本 gem 以 MIT 许可证开源 - 详见 [MIT-LICENSE](MIT-LICENSE) 文件。

## 致谢

- [RailsWarp](https://github.com/afeiship/rails_warp) - 统一的响应格式
- [Kaminari](https://github.com/kaminari/kaminari) - 分页功能
- [rails_api_base](https://github.com/afeiship/rails_api_base) - 参考实现

## 支持

如有问题或建议，请：
- 提交 [Issue](https://github.com/afeiship/rails_curd_base/issues)
- 发送 Pull Request
- 联系作者：1290657123@qq.com
