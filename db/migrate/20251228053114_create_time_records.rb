class CreateTimeRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :time_records do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :event_type, null: false
      t.datetime :recorded_at, null: false
      t.timestamps
    end
  end
end
