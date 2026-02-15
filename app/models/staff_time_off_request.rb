class StaffTimeOffRequest < ApplicationRecord
  belongs_to :user

  enum request_type: { preferred: 0, fixed: 1 }

  validates :target_date, presence: true
  validates :user_id, uniqueness: { scope: :target_date, message: "同じ日に複数の希望は出せません" }
  validates :request_type, presence: true

  scope :for_month, ->(date) {
    bom = date.beginning_of_month
    eom = date.end_of_month
    where(target_date: bom..eom)
  }

  def self.request_type_label(key)
    { "preferred" => "希望", "fixed" => "固定休" }[key.to_s] || key.to_s
  end
end
