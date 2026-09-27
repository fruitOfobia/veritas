class Address < ApplicationRecord
  belongs_to :user
  has_many :orders, dependent: :nullify

  validates :line1, :city, :state, :pincode, presence: true
  validates :pincode, format: { with: /\A\d{6}\z/, message: "must be a 6-digit PIN code" }

  before_save :demote_other_defaults, if: :is_default?

  def to_s
    [ label, line1, line2, landmark, city, "#{state} #{pincode}" ].compact_blank.join(", ")
  end

  private

  def demote_other_defaults
    user.addresses.where.not(id: id).update_all(is_default: false)
  end
end
