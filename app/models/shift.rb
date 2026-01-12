class Shift < ApplicationRecord
  belongs_to :user
  belongs_to :group
  belongs_to :shift_pattern
  has_many :shift_details, dependent: :destroy
  has_many :shifts, dependent: :restrict_with_error

  validates :work_date, presence: true
  validates :user_id, uniqueness: { scope: :work_date }

  validate :group_consistency

  # ShiftPattern と同じ配列生成（0..95）
  def slots_array
    arr = Array.new(ShiftPattern::SLOTS_PER_DAY, nil)
    shift_details.each do |d|
      arr[d.slot_index] = d.time_block_id
    end
    arr
  end

  # パターンからその日の詳細へコピー（スナップショット化）
  def snapshot_from_pattern!
    return if shift_pattern.nil?

    now = Time.current

    # 既存を消して作り直し（最初はこの方が事故りにくい）
    shift_details.delete_all

    rows = shift_pattern.shift_pattern_details.map do |d|
      {
        shift_id: id,
        slot_index: d.slot_index,
        time_block_id: d.time_block_id,
        created_at: now,
        updated_at: now
      }
    end

    ShiftDetail.insert_all(rows) if rows.present?
  end

  def apply_pattern!(pattern)
    self.shift_pattern = pattern
    self.group_id = pattern.group_id
    save!

    snapshot_from_pattern!
    self
  end

  private

  def group_consistency
    return if shift_pattern.nil? || group_id.nil?
    errors.add(:group_id, "がシフトパターンの所属グループと一致しません") if group_id != shift_pattern.group_id

    if user&.group_id.present? && group_id != user.group_id
      errors.add(:group_id, "がスタッフの所属グループと一致しません")
    end
  end
end
