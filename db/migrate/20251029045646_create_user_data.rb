class CreateUserData < ActiveRecord::Migration[8.1]
  def change
    create_table :user_data do |t|
      t.bigint :user_id, null: false

      t.timestamps
    end

    add_index :user_data, :user_id, unique: true
  end
end
