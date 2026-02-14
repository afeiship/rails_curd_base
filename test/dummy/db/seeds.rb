# 种子数据 - 用于测试
Post.create!(
  title: "First Post",
  content: "This is the first post content",
  status: "published",
  published_at: 1.day.ago
)

Post.create!(
  title: "Second Post",
  content: "This is the second post content",
  status: "draft"
)

Post.create!(
  title: "Third Post",
  content: "This is the third post about Ruby on Rails",
  status: "published",
  published_at: Time.current
)

puts "Created #{Post.count} posts"
