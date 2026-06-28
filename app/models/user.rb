class User < ApplicationRecord
  BANNED = "banned"
  NOT_BANNED = "not_banned"

  has_many :integrity_logs, foreign_key: :idfa, primary_key: :idfa, inverse_of: false

  validates :idfa, presence: true, uniqueness: true
  validates :ban_status, presence: true

  scope :banned, -> { where(ban_status: BANNED) }
  scope :not_banned, -> { where(ban_status: NOT_BANNED) }

  def banned?
    ban_status == BANNED
  end

  def not_banned?
    ban_status == NOT_BANNED
  end
end
