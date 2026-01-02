class DeviseCreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email,               null: false, default: ""
      t.string :encrypted_password,  null: false, default: ""
      t.string :name,                null: false
      t.integer :role,               null: false, default: 0
      t.references :group,           foreign_key: true           
      t.string :employee_number,     null: false
      t.date :joined_on,             null: false
      t.date :retired_on
      t.integer :employment_type, null: false, default: 0
      t.integer :position,        null: false, default: 2
      t.integer :salary_type,     null: false, default: 0
      t.integer :salary_amount,      null: false
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      t.datetime :remember_created_at

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :employee_number,      unique:true
    add_index :users, :role
  end
end
