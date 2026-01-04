class TimeBlock < ApplicationRecord
  validates :name, presence: true, length: { maximum: 50 }, uniqueness: true

  validates :color_code,
            presence: true,
            format: { with: /\A#(?:\h{6})\z/i, message: "は #RRGGBB 形式で入力してください" }
end
