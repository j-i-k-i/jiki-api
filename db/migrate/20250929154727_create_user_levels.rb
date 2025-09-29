class CreateUserLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :user_levels do |t|
      t.references :user, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true

      t.timestamps
    end

    add_index :user_levels, %i[user_id level_id], unique: true
  end
end
