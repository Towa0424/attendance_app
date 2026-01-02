class TimeRecord < ApplicationRecord
  belongs_to :user

  enum event_type: {
    clock_in: 0,     # 出勤
    clock_out: 1,    # 退勤
    break_start: 2,  # 休始
    break_end: 3     # 休終
  }

  validates :date, :event_type, :recorded_at, presence: true
  validates :event_type, uniqueness: { scope: [:user_id, :date] }
end
