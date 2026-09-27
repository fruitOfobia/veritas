require "rails_helper"

RSpec.describe Category, type: :model do
  it "is valid with a name and an auto-generated slug" do
    category = build(:category, name: "Kitchen", slug: nil)
    expect(category).to be_valid
    category.save!
    expect(category.slug).to eq("kitchen")
  end

  it "requires a unique slug" do
    create(:category, name: "Bathroom", slug: "bathroom")
    duplicate = build(:category, name: "Bathroom Again", slug: "bathroom")
    expect(duplicate).not_to be_valid
  end

  it "supports a parent/subcategory tree" do
    parent = create(:category, name: "Kitchen")
    child = create(:category, name: "Sinks", parent: parent)

    expect(parent.subcategories).to include(child)
    expect(parent).to be_top_level
    expect(child).not_to be_top_level
  end

  it "destroys subcategories and products when destroyed" do
    parent = create(:category)
    child = create(:category, parent: parent)
    product = create(:product, category: parent)

    parent.destroy

    expect(Category.exists?(child.id)).to be false
    expect(Product.exists?(product.id)).to be false
  end
end
