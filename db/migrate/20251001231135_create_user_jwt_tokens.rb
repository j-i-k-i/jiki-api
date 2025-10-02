class CreateUserJwtTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :user_jwt_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :jti, null: false
      t.string :aud
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :user_jwt_tokens, :jti, unique: true
    add_index :user_jwt_tokens, :expires_at
  end
end
