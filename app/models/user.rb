class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { customer: 0, admin: 1 }, default: :customer

  has_one :cart, dependent: :destroy
  has_one :wishlist, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :product_reviews, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true

  after_create :provision_defaults!

  def name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  def default_address
    addresses.find_by(is_default: true) || addresses.first
  end

  private

  def provision_defaults!
    Cart.find_or_create_by!(user: self)
    Wishlist.find_or_create_by!(user: self)
  end
end
