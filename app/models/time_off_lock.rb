class TimeOffLock < ApplicationRecord
  belongs_to :group

  validates :target_month, presence: true
  validates :group_id, uniqueness: { scope: :target_month }

  scope :for_month, ->(date) { where(target_month: date.beginning_of_month) }

  def self.locked?(group_id, month)
    where(group_id: group_id, target_month: month.beginning_of_month, locked: true).exists?
  end
end
