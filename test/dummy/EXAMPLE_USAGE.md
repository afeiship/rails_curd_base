# RailsCurdBase 示例使用指南

本目录包含一个完整的示例，展示如何使用 `rails_curd_base` gem。

## 前置要求

确保你的应用已安装以下依赖：

1. **kaminari** - 分页支持（必需）
2. **rails_warp** - 统一响应格式（必需）

在 Gemfile 中添加：

```ruby
gem "kaminari"
gem "rails_warp"
```

然后运行：

```bash
bundle install
```

## 示例：Posts API

### 1. 模型定义

```ruby
class Post < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true

  # 搜索作用域（可选）
  scope :search, ->(keyword) {
    return all if keyword.blank?
    where("title LIKE ? OR content LIKE ?", "%#{keyword}%", "%#{keyword}%")
  }
end
```

### 2. 控制器实现

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  # 启用查询功能
  supports_query(
    pagination: { enabled: true, default_per: 10, max_per: 50 },
    sorting: { enabled: true, allowed_fields: [:id, :title, :created_at, :updated_at] },
    searching: { enabled: true, searchable_fields: [:title, :content] },
    filtering: { enabled: true, filterable_fields: [:status] }
  )

  # 可选：添加钩子
  def before_create(resource)
    resource.published_at = Time.current if resource.status == 'published'
    true
  end
end
```

### 3. 路由配置

```ruby
Rails.application.routes.draw do
  namespace :api do
    resources :posts
  end
end
```

## API 使用示例

### 获取文章列表（带分页、排序、搜索）

```bash
# 基础分页
GET /api/posts?page=1&size=10

# 排序
GET /api/posts?sort=-created_at  # 降序
GET /api/posts?sort=title         # 升序

# 搜索
GET /api/posts?q=hello

# 过滤
GET /api/posts?filter[status]=published

# 组合使用
GET /api/posts?page=1&size=20&sort=-created_at&q=rails&filter[status]=published
```

### 响应格式

成功响应：
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

错误响应：
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

### 创建文章

```bash
POST /api/posts
{
  "post": {
    "title": "Hello World",
    "content": "This is my first post",
    "status": "published"
  }
}
```

### 更新文章

```bash
PUT /api/posts/1
{
  "post": {
    "title": "Updated Title"
  }
}
```

### 删除文章

```bash
DELETE /api/posts/1
```

## 生命周期钩子

CurdController 提供了多个生命周期钩子：

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  # 创建前
  def before_create(resource)
    resource.author = current_user
    true  # 返回 false 会中止保存
  end

  # 创建后
  def after_create(resource)
    NotificationService.notify(resource)
  end

  # 更新前
  def before_update(resource)
    resource.editor = current_user
    true
  end

  # 更新后
  def after_update(resource)
    CacheService.invalidate(resource)
  end
end
```

## 自定义 Collection

如果需要限制数据范围或添加关联：

```ruby
class Api::PostsController < RailsCurdBase::CurdController
  def collection
    # 只返回当前用户的文章
    current_user.posts
  end
end
```

## Queryable 功能详解

### 分页配置

```ruby
supports_query(
  pagination: {
    enabled: true,
    default_per: 20,    # 默认每页数量
    max_per: 100,        # 最大每页数量
    page_param: :page,   # 页码参数名
    per_param: :size      # 每页数量参数名
  }
)
```

### 排序配置

```ruby
supports_query(
  sorting: {
    enabled: true,
    allowed_fields: [:id, :title, :created_at, :updated_at],
    sort_param: :sort,
    default_direction: :asc
  }
)
```

使用：
- `?sort=title` → 升序
- `?sort=-title` → 降序

### 搜索配置

```ruby
supports_query(
  searching: {
    enabled: true,
    searchable_fields: [:title, :content],
    search_param: :q
  }
)
```

### 过滤配置

```ruby
supports_query(
  filtering: {
    enabled: true,
    filterable_fields: [:status, :category_id],
    filter_param: :filter
  }
)
```

支持的操作符：
- `?filter[status]=published` → 等于
- `?filter[status][neq]=draft` → 不等于
- `?filter[category_id][gte]=10` → 大于等于
- `?filter[category_id][in]=1,2,3` → 在数组中

## 资源自动推导

CurdController 会自动从控制器名称推导资源类：

- `Api::PostsController` → `Post` 模型
- `Api::UsersController` → `User` 模型
- `Api::CommentsController` → `Comment` 模型

如果需要自定义，可以覆盖 `resource_class` 方法：

```ruby
def resource_class
  CustomPost
end
```

## 运行示例

1. 迁移数据库：
```bash
cd test/dummy
bin/rails db:migrate
```

2. 启动服务器：
```bash
bin/rails server
```

3. 测试 API：
```bash
curl http://localhost:3000/api/posts
```
