class CreateUserConcepts < ActiveRecord::Migration[8.1]
  def change
    create_table :user_concepts do |t|
      t.bigint :user_id, null: false
      t.bigint :concept_id, null: false

      t.timestamps
    end

    add_index :user_concepts, [:user_id, :concept_id], unique: true
    add_index :user_concepts, :concept_id
  end
end
