class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :status, default: 'draft'
      t.datetime :published_at

      t.timestamps
    end

    add_index :posts, :status
    add_index :posts, :created_at
  end
end
