class CreateUserLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :user_levels do |t|
      t.references :user, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true
      t.references :current_user_lesson, null: true, foreign_key: { to_table: :user_lessons }
      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :user_levels, %i[user_id level_id], unique: true

    # Add foreign key and index from users.current_user_level_id to user_levels (now that user_levels exists)
    add_foreign_key :users, :user_levels, column: :current_user_level_id
    add_index :users, :current_user_level_id
  end
end
