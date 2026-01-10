class Group < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :shift_patterns, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
end
