class CreateLessons < ActiveRecord::Migration[8.0]
  def change
    create_table :lessons do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.string :type, null: false
      t.json :data, null: false, default: {}
      t.integer :position, null: false
      t.references :level, null: false, foreign_key: true

      t.timestamps
    end
    add_index :lessons, :slug, unique: true
    add_index :lessons, %i[level_id position], unique: true
    add_index :lessons, :type
  end
end
