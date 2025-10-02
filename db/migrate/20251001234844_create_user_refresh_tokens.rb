class CreateUserRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :user_refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :crypted_token, null: false
      t.string :aud
      t.datetime :exp, null: false

      t.timestamps
    end

    add_index :user_refresh_tokens, :crypted_token, unique: true
  end
end
