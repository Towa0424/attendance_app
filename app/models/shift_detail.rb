class ShiftDetail < ApplicationRecord
  belongs_to :shift
  belongs_to :time_block

  validates :slot_index,
            presence: true,
            inclusion: { in: 0..(ShiftPattern::SLOTS_PER_DAY - 1) }

  validates :slot_index, uniqueness: { scope: :shift_id }
end
