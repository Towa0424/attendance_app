class CreateShiftDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :shift_details do |t|
      t.references :shift, null: false, foreign_key: true
      t.integer :slot_index, null: false
      t.references :time_block, null: false, foreign_key: true

      t.timestamps
    end

    add_index :shift_details, [:shift_id, :slot_index],
              unique: true,
              name: "idx_shift_details_shift_slot"

    add_check_constraint :shift_details,
                         "slot_index >= 0 AND slot_index <= 95",
                         name: "chk_shift_details_slot_range"
  end
end
