class CreateExerciseSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :exercise_submissions do |t|
      t.references :user_lesson, null: false, foreign_key: true
      t.string :uuid, null: false

      t.timestamps
    end
    add_index :exercise_submissions, :uuid, unique: true
  end
end
