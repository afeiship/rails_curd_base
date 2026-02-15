class Api::PostsController < RailsCurdBase::CurdController
  # 启用查询功能
  supports_query(
    pagination: { enabled: true, default_per: 10, max_per: 50 },
    sorting: { enabled: true, allowed_fields: [:id, :title, :created_at, :updated_at] },
    searching: { enabled: true, searchable_fields: [:title, :content] },
    filtering: { enabled: true, filterable_fields: [:status] }
  )

  # 配置 index 返回的字段（列表页不需要所有字段）
  index_fields :id, :title, :status, :created_at

  # 配置 show 返回的字段（详情页需要完整信息）
  show_fields :id, :title, :content, :status, :published_at, :created_at, :updated_at

  # 可选：自定义 collection
  # def collection
  #   Post.all
  # end

  # 可选：添加钩子
  def before_create(resource)
    resource.published_at = Time.current if resource.status == 'published'
    true
  end

  def after_create(resource)
    Rails.logger.info "Post created: #{resource.id}"
  end
end
