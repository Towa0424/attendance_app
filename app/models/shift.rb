class Shift < ApplicationRecord
  belongs_to :user
  belongs_to :group
  belongs_to :shift_pattern

  has_many :shift_details, dependent: :destroy

  validates :work_date, presence: true
  validate :group_consistency

  # 日別ガント用（0..95 の time_block_id 配列）
  def slots_array
    arr = Array.new(96)
    shift_details.each { |d| arr[d.slot_index] = d.time_block_id }
    arr
  end

  # 選択されたシフトパターンを適用し、shift_details を再生成する
  def apply_pattern!(pattern)
    self.shift_pattern = pattern
    self.group_id = pattern.group_id
    save!
    snapshot_from_pattern!
  end

  # shift_pattern_details から 15分スロットを shift_details にスナップショットする
  def snapshot_from_pattern!
    shift_details.delete_all

    now = Time.current
    rows =
      shift_pattern.shift_pattern_details
                  .order(:start_slot)
                  .flat_map do |d|
        (d.start_slot...d.end_slot).map do |slot|
          {
            shift_id: id,
            slot_index: slot,
            time_block_id: d.time_block_id,
            created_at: now,
            updated_at: now
          }
        end
      end

    ShiftDetail.insert_all(rows) if rows.any?
  end

  private

  def group_consistency
    return if shift_pattern.blank? || group_id.blank?
    errors.add(:group, "がシフトパターンの所属グループと一致しません") if group_id != shift_pattern.group_id
  end
end
