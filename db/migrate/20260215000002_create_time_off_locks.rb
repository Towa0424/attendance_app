class CreateTimeOffLocks < ActiveRecord::Migration[7.1]
  def change
    create_table :time_off_locks do |t|
      t.references :group, null: false, foreign_key: true
      t.date :target_month, null: false
      t.boolean :locked, null: false, default: false

      t.timestamps
    end

    add_index :time_off_locks, [:group_id, :target_month], unique: true, name: "idx_time_off_lock_group_month"
  end
end
