class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  # 権限
  enum role: { staff: 0, admin: 1 }

  # 雇用形態
  enum employment_type: { full_time: 0, part_time: 1, dispatch: 2 }

  # 役職（※権限の admin と別概念）
  enum position: { administrator: 0, sv: 1, communicator: 2 }

  # 給与タイプ
  enum salary_type: { hourly: 0, monthly: 1 }

  belongs_to :group, optional: true
  has_many :time_records, dependent: :destroy
  has_many :shifts, dependent: :destroy
end
