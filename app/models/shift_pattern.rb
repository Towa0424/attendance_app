class ShiftPattern < ApplicationRecord
  belongs_to :group
  has_many :shift_pattern_details, dependent: :destroy

  validates :name, presence: true

  SLOT_MINUTES = 15
  SLOTS_PER_DAY = 96

  DEFAULT_START_SLOT = 36 # 09:00
  DEFAULT_END_SLOT   = 80 # 20:00

  def slots_array
    arr = Array.new(SLOTS_PER_DAY, nil)
    shift_pattern_details.each do |d|
      arr[d.slot_index] = d.time_block_id
    end
    arr
  end

  def self.slot_to_hhmm(slot)
    total = slot.to_i * SLOT_MINUTES
    hh = (total / 60) % 24
    mm = total % 60
    format("%02d:%02d", hh, mm)
  end

  def self.blocks_from_slots(slots, range_start:, range_end:)
    blocks = []
    cur_id = nil
    cur_start = nil

    (range_start...range_end).each do |i|
      id = slots[i]
      if id != cur_id
        blocks << { start: cur_start, end: i, time_block_id: cur_id } if cur_id.present?
        cur_id = id
        cur_start = i
      end
    end

    blocks << { start: cur_start, end: range_end, time_block_id: cur_id } if cur_id.present?
    blocks
  end

  def self.display_range_for(patterns)
    ids = patterns.map(&:id)
    return [DEFAULT_START_SLOT, DEFAULT_END_SLOT] if ids.blank?

    scope = ShiftPatternDetail.where(shift_pattern_id: ids)
    min_slot = scope.minimum(:slot_index)
    max_slot = scope.maximum(:slot_index)

    return [DEFAULT_START_SLOT, DEFAULT_END_SLOT] if min_slot.nil? || max_slot.nil?

    start_slot = (min_slot / 4) * 4
    end_excl   = max_slot + 1
    end_slot   = ((end_excl + 3) / 4) * 4
    end_slot = [end_slot, SLOTS_PER_DAY].min

    [start_slot, end_slot]
  end

  # --- ここから追加 ---

  # 使用している時間ブロックの一覧（出現順）＋合計分数
  # return: [{time_block:, minutes:, first_slot:}, ...]
  def time_block_usage
    return [] if shift_pattern_details.blank?

    # shift_pattern_details は controller 側で :time_block を includes 済みの前提
    grouped = shift_pattern_details.group_by(&:time_block_id)

    grouped.map do |_time_block_id, details|
      tb = details.first.time_block
      first_slot = details.min_by(&:slot_index).slot_index
      minutes = details.size * SLOT_MINUTES

      { time_block: tb, minutes: minutes, first_slot: first_slot }
    end.sort_by { |h| h[:first_slot] }
  end

  def self.minutes_to_hhmm(minutes)
    m = minutes.to_i
    h = m / 60
    mm = m % 60
    format("%d:%02d", h, mm)
  end
end
