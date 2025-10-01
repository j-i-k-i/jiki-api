class CreateExerciseSubmissionFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :exercise_submission_files do |t|
      t.references :exercise_submission, null: false, foreign_key: true
      t.string :filename, null: false
      t.string :digest, null: false

      t.timestamps
    end
  end
end
