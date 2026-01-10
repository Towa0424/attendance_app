class CreateShiftPatterns < ActiveRecord::Migration[7.1]
  def change
    create_table :shift_patterns do |t|
      t.string :name, null: false
      t.references :group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
