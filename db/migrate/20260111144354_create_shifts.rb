class CreateShifts < ActiveRecord::Migration[7.1]
  def change
    create_table :shifts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.date :work_date, null: false

      t.references :shift_pattern, null: true, foreign_key: true

      t.timestamps
    end

    add_index :shifts, [:user_id, :work_date], unique: true
    add_index :shifts, [:group_id, :work_date]
  end
end
