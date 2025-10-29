class CreateUserData < ActiveRecord::Migration[8.1]
  def change
    create_table :user_data do |t|
      t.bigint :user_id, null: false
      t.bigint :unlocked_concept_ids, array: true, default: [], null: false

      t.timestamps
    end

    add_index :user_data, :user_id, unique: true
    add_index :user_data, :unlocked_concept_ids, using: :gin
  end
end
