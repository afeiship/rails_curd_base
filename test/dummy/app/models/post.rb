class Post < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true

  # 搜索作用域（可选）
  scope :search, ->(keyword) {
    return all if keyword.blank?
    where("title LIKE ? OR content LIKE ?", "%#{keyword}%", "%#{keyword}%")
  }
end
