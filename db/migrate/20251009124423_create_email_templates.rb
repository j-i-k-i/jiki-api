class CreateEmailTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :email_templates do |t|
      t.integer :template_type, null: false
      t.string :key
      t.string :locale, null: false
      t.text :subject, null: false
      t.text :body_mjml, null: false
      t.text :body_text, null: false

      t.timestamps
    end

    add_index :email_templates, %i[template_type key locale], unique: true
  end
end
