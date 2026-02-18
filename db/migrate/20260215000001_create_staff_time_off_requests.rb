class CreateStaffTimeOffRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :staff_time_off_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.date :target_date, null: false
      t.integer :request_type, null: false, default: 0
      t.timestamps
    end

    add_index :staff_time_off_requests, [:user_id, :target_date], unique: true, name: "idx_time_off_user_date"
  end
end
