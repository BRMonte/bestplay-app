class IntegrityLog < ApplicationRecord
  self.record_timestamps = false

  belongs_to :user, foreign_key: :idfa, primary_key: :idfa, inverse_of: false, optional: true

  validates :idfa, :ban_status, presence: true
  validates :rooted_device, inclusion: { in: [ true, false ] }
  validates :proxy, :vpn, inclusion: { in: [ true, false ] }

  before_validation :set_created_at, on: :create

  private

  def set_created_at
    self.created_at ||= Time.current
  end
end
