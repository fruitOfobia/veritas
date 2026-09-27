require "rails_helper"

RSpec.describe Order, type: :model do
  it "generates a unique order_number on create" do
    order = create(:order)
    expect(order.order_number).to be_present
    expect(order.order_number).to start_with("BB")
  end

  it "defaults to pending status and cod payment method" do
    order = create(:order)
    expect(order).to be_pending
    expect(order).to be_cod
  end

  describe "#cancellable?" do
    it "is true while pending or confirmed" do
      expect(build(:order, status: :pending)).to be_cancellable
      expect(build(:order, status: :confirmed)).to be_cancellable
    end

    it "is false once shipped, delivered or cancelled" do
      expect(build(:order, status: :shipped)).not_to be_cancellable
      expect(build(:order, status: :delivered)).not_to be_cancellable
      expect(build(:order, status: :cancelled)).not_to be_cancellable
    end
  end

  it "increments the coupon's used_count when placed with a coupon" do
    coupon = create(:coupon, used_count: 0)
    expect { create(:order, coupon: coupon) }.to change { coupon.reload.used_count }.by(1)
  end
end
