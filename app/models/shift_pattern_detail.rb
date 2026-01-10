class ShiftPatternDetail < ApplicationRecord
  belongs_to :shift_pattern
  belongs_to :time_block

  validates :slot_index, presence: true, inclusion: { in: 0..95 }
  validates :slot_index, uniqueness: { scope: :shift_pattern_id }
end
