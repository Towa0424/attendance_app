class CreateGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :groups do |t|
      t.string :name,             null: false
      t.integer :work_start_slot, null: false
      t.integer :work_end_slot,   null: false
      t.timestamps
    end
  end
end
