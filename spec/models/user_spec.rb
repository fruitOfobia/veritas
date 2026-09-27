require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with an email, password, first and last name" do
    expect(build(:user)).to be_valid
  end

  it "defaults to the customer role" do
    expect(create(:user)).to be_customer
  end

  it "auto-provisions a cart and a wishlist on creation" do
    user = create(:user)
    expect(user.cart).to be_present
    expect(user.wishlist).to be_present
  end

  describe "#name" do
    it "joins first and last name" do
      user = build(:user, first_name: "Jane", last_name: "Doe")
      expect(user.name).to eq("Jane Doe")
    end
  end

  describe "#default_address" do
    it "returns the address flagged is_default, falling back to the first address" do
      user = create(:user)
      create(:address, user: user, is_default: false, label: "Office")
      default_address = create(:address, user: user, is_default: true, label: "Home")

      expect(user.default_address).to eq(default_address)
    end
  end
end
