class AddStartedAtAndCompletedAtToUserLessons < ActiveRecord::Migration[8.0]
  def change
    add_column :user_lessons, :started_at, :datetime, null: false
    add_column :user_lessons, :completed_at, :datetime
  end
end
