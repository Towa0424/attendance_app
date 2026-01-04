class CreateTimeBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :time_blocks do |t|
      t.string  :name,       null: false
      t.string  :color_code, null: false
      t.boolean :has_cost,   null: false, default: true
      t.boolean :has_sales,  null: false, default: true

      t.timestamps
    end

    add_index :time_blocks, :name, unique: true
  end
end
