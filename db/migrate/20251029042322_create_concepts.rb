class CreateConcepts < ActiveRecord::Migration[8.1]
  def change
    create_table :concepts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description, null: false
      t.text :content_markdown, null: false
      t.text :content_html, null: false
      t.string :standard_video_provider
      t.string :standard_video_id
      t.string :premium_video_provider
      t.string :premium_video_id

      t.timestamps
    end

    add_index :concepts, :slug, unique: true
  end
end
