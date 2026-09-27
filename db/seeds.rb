# frozen_string_literal: true

require "zlib"

#
# Seed data for BuildBazaar. All names, descriptions and images below are original
# placeholder content — nothing is copied from any real retailer's catalog.

# Generates a simple, on-brand placeholder "product photo" as a real PNG — no external
# network call and no ImageMagick/libvips dependency, so seeding always works offline.
# (SVG was tried first, but Rails' Active Storage serves image/svg+xml as a forced
# download for XSS safety, so it never renders inline in an <img> tag — PNG does.)
PLACEHOLDER_PALETTE = [
  [ 247, 134, 10 ],  # brand amber
  [ 15, 157, 143 ],  # teal
  [ 59, 91, 219 ],   # slate blue
  [ 232, 89, 12 ],   # terracotta
  [ 47, 158, 68 ],   # forest green
  [ 156, 54, 181 ],  # plum
  [ 73, 80, 87 ],    # steel
  [ 194, 37, 92 ]    # rose
].freeze

def png_chunk(type, data)
  [ data.bytesize ].pack("N") + type + data + [ Zlib.crc32(type + data) ].pack("N")
end

# A minimal, dependency-free PNG encoder: a solid-color tile with a soft circular
# highlight and a simple pentagon "package" icon — no text (the product name/category
# are already shown as real text next to the image on every page).
def placeholder_png(rgb, size: 400)
  r, g, b = rgb
  cx = cy = size / 2.0
  glow_radius = size * 0.32
  icon = size * 0.16 # icon bounding box half-width, roughly centered

  pentagon = [
    [ cx, cy - icon * 1.15 ],
    [ cx + icon, cy - icon * 0.35 ],
    [ cx + icon, cy + icon ],
    [ cx - icon, cy + icon ],
    [ cx - icon, cy - icon * 0.35 ]
  ]

  raw = String.new(encoding: Encoding::BINARY)
  size.times do |y|
    raw << 0.chr
    size.times do |x|
      dist = Math.sqrt(((x - cx)**2) + ((y - cy)**2))
      if dist < glow_radius
        t = 0.16
        pr = ((r * (1 - t)) + (255 * t)).round
        pg = ((g * (1 - t)) + (255 * t)).round
        pb = ((b * (1 - t)) + (255 * t)).round
      else
        pr, pg, pb = r, g, b
      end

      if point_in_polygon?(x, y, pentagon) && !point_in_polygon?(x, y, pentagon, shrink: 6)
        pr, pg, pb = 255, 255, 255
      elsif (y - cy).abs < 3 && (x - cx).abs < icon
        pr, pg, pb = 255, 255, 255
      end

      raw << pr.chr << pg.chr << pb.chr
    end
  end

  ihdr = [ size, size, 8, 2, 0, 0, 0 ].pack("N N C C C C C")
  compressed = Zlib::Deflate.deflate(raw, Zlib::BEST_SPEED)

  "\x89PNG\r\n\x1a\n".b + png_chunk("IHDR", ihdr) + png_chunk("IDAT", compressed) + png_chunk("IEND", "")
end

# Ray-casting point-in-polygon test; `shrink` insets the polygon toward its centroid
# so we can render a polygon "outline" (ring) by subtracting a smaller copy of itself.
def point_in_polygon?(x, y, polygon, shrink: 0)
  if shrink.positive?
    cx = polygon.sum { |p| p[0] } / polygon.size.to_f
    cy = polygon.sum { |p| p[1] } / polygon.size.to_f
    polygon = polygon.map do |px, py|
      dx, dy = px - cx, py - cy
      len = Math.sqrt((dx**2) + (dy**2))
      next [ px, py ] if len.zero?

      [ px - (dx / len * shrink), py - (dy / len * shrink) ]
    end
  end

  inside = false
  j = polygon.size - 1
  polygon.each_index do |i|
    xi, yi = polygon[i]
    xj, yj = polygon[j]
    if (yi > y) != (yj > y) && x < (((xj - xi) * (y - yi) / (yj - yi)) + xi)
      inside = !inside
    end
    j = i
  end
  inside
end

def attach_placeholder_image!(product, rgb)
  return if product.images.attached?

  product.images.attach(
    io: StringIO.new(placeholder_png(rgb)),
    filename: "#{product.slug}.png",
    content_type: "image/png"
  )
end

puts "Seeding BuildBazaar…"

ActiveRecord::Base.transaction do
  admin = User.find_or_initialize_by(email: "admin@buildbazaar.test")
  admin.assign_attributes(
    password: "password123",
    password_confirmation: "password123",
    first_name: "Store",
    last_name: "Admin",
    role: :admin
  )
  admin.save!

  demo = User.find_or_initialize_by(email: "demo@buildbazaar.test")
  demo.assign_attributes(
    password: "password123",
    password_confirmation: "password123",
    first_name: "Demo",
    last_name: "Customer",
    role: :customer,
    company_name: "Sharma Interiors",
    gstin: "29ABCDE1234F1Z5"
  )
  demo.save!

  demo.addresses.find_or_create_by!(line1: "12, MG Road") do |a|
    a.label = "Home"
    a.city = "Bengaluru"
    a.state = "Karnataka"
    a.pincode = "560001"
    a.is_default = true
  end

  puts "  Users ready: #{admin.email} / #{demo.email} (password: password123)"
end

CATALOG = {
  "Kitchen" => {
    desc: "Countertops, sinks, laminates and fittings for a functional kitchen.",
    products: [
      { name: "Quartz Kitchen Countertop Slab", unit: "sq.ft", price: 1450, mrp: 1800 },
      { name: "Stainless Steel Double Bowl Sink", unit: "piece", price: 3200, mrp: 3900 },
      { name: "High-Gloss Kitchen Laminate Sheet", unit: "sheet", price: 2100, mrp: nil },
      { name: "Soft-Close Kitchen Cabinet Hinges (Pack of 10)", unit: "pack", price: 850, mrp: 999 },
      { name: "Modular Kitchen Basket Set", unit: "set", price: 4500, mrp: 5200 }
    ]
  },
  "Bathroom" => {
    desc: "Basins, faucets, tiles and accessories for every bathroom.",
    products: [
      { name: "Ceramic Wall-Mounted Wash Basin", unit: "piece", price: 2800, mrp: 3400 },
      { name: "Single Lever Basin Mixer Faucet", unit: "piece", price: 1650, mrp: 1950 },
      { name: "Anti-Skid Bathroom Floor Tile 300x300mm", unit: "sq.ft", price: 65, mrp: 85 },
      { name: "Rain Shower Head with Arm", unit: "set", price: 2200, mrp: nil }
    ]
  },
  "Wardrobe" => {
    desc: "Laminates, hardware and fittings for custom wardrobes.",
    products: [
      { name: "Matte-Finish Wardrobe Laminate Sheet", unit: "sheet", price: 1900, mrp: 2300 },
      { name: "Wardrobe Sliding Door Track Set", unit: "set", price: 3100, mrp: nil },
      { name: "Wardrobe Drawer Channel 18-inch", unit: "pair", price: 420, mrp: 500 }
    ]
  },
  "Hardware" => {
    desc: "Handles, locks, hinges and fasteners for every part of the home.",
    products: [
      { name: "Stainless Steel Door Handle Set", unit: "set", price: 950, mrp: 1150 },
      { name: "Heavy Duty Cabinet Lock", unit: "piece", price: 380, mrp: nil },
      { name: "Concealed Door Hinge (Pack of 4)", unit: "pack", price: 560, mrp: 650 }
    ]
  },
  "Electrical" => {
    desc: "Wires, switches, lighting and fans for safe, modern wiring.",
    products: [
      { name: "Modular Switch Plate (4-Way)", unit: "piece", price: 320, mrp: 380 },
      { name: "1.5 Sq.mm Copper Wire (90m Coil)", unit: "coil", price: 2450, mrp: 2750 },
      { name: "LED Ceiling Light Panel 24W", unit: "piece", price: 780, mrp: 950 },
      { name: "Energy-Efficient Ceiling Fan", unit: "piece", price: 2600, mrp: 3100 }
    ]
  },
  "Plumbing" => {
    desc: "Pipes, valves and fittings for reliable water supply and drainage.",
    products: [
      { name: "CPVC Plumbing Pipe 1-inch (3m)", unit: "piece", price: 340, mrp: nil },
      { name: "Brass Gate Valve 1/2-inch", unit: "piece", price: 480, mrp: 560 },
      { name: "PVC Drainage Elbow Fitting", unit: "piece", price: 95, mrp: nil }
    ]
  },
  "Flooring" => {
    desc: "Tiles, wooden flooring and waterproofing for every surface.",
    products: [
      { name: "Vitrified Floor Tile 600x600mm", unit: "sq.ft", price: 72, mrp: 95 },
      { name: "Laminate Wooden Flooring Plank", unit: "sq.ft", price: 110, mrp: 135 },
      { name: "Waterproofing Membrane Coating (20L)", unit: "drum", price: 3800, mrp: 4200 }
    ]
  },
  "Wall Finishes" => {
    desc: "Paints, putty, plywood and wallpaper for interior and exterior walls.",
    products: [
      { name: "Interior Emulsion Paint (20L)", unit: "drum", price: 4200, mrp: 4800 },
      { name: "Wall Putty (40kg Bag)", unit: "bag", price: 950, mrp: nil },
      { name: "Waterproof Plywood Sheet 19mm", unit: "sheet", price: 3600, mrp: 4100 },
      { name: "Textured Wallpaper Roll", unit: "roll", price: 1450, mrp: 1700 }
    ]
  },
  "Adhesives & Sealants" => {
    desc: "Tile adhesives, silicone sealants and bonding solutions.",
    products: [
      { name: "Tile Adhesive (20kg Bag)", unit: "bag", price: 620, mrp: nil },
      { name: "Silicone Sealant Cartridge", unit: "piece", price: 280, mrp: 330 }
    ]
  },
  "Blinds & Window Treatments" => {
    desc: "Roller blinds, curtains and window fittings.",
    products: [
      { name: "Roller Blind - Blackout Fabric", unit: "sq.ft", price: 180, mrp: 220 },
      { name: "Vertical Blind Track System", unit: "set", price: 1350, mrp: nil }
    ]
  },
  "Building Materials" => {
    desc: "Cement, steel, sand and core construction materials.",
    products: [
      { name: "OPC 53 Grade Cement (50kg Bag)", unit: "bag", price: 420, mrp: nil },
      { name: "TMT Steel Reinforcement Bar 12mm", unit: "quintal", price: 5800, mrp: 6100 },
      { name: "Red Clay Building Brick (Per 1000)", unit: "lot", price: 7200, mrp: nil }
    ]
  },
  "Tool Rentals" => {
    desc: "Power tools and equipment available for short-term rental.",
    products: [
      { name: "Rotary Hammer Drill (Daily Rental)", unit: "day", price: 450, mrp: nil },
      { name: "Concrete Mixer (Daily Rental)", unit: "day", price: 1200, mrp: nil },
      { name: "Tile Cutter Machine (Daily Rental)", unit: "day", price: 650, mrp: nil }
    ]
  }
}.freeze

CATALOG.each_with_index do |(name, data), index|
  category = Category.find_or_initialize_by(slug: name.parameterize)
  category.assign_attributes(name: name, description: data[:desc], position: index, is_active: true)
  category.save!

  data[:products].each_with_index do |product_attrs, p_index|
    sku = "#{category.slug.upcase[0, 4]}-#{p_index + 1}"
    product = Product.find_or_initialize_by(sku: sku)
    product.assign_attributes(
      category: category,
      name: product_attrs[:name],
      description: "#{product_attrs[:name]} — a reliable choice for #{category.name.downcase} projects, " \
                    "suitable for residential and commercial use.",
      price: product_attrs[:price],
      mrp: product_attrs[:mrp],
      unit: product_attrs[:unit],
      stock: rand(5..80),
      is_active: true,
      is_featured: p_index.zero? && index < 8,
      specifications: { "Brand" => "BuildBazaar Select", "Warranty" => "6 months", "Origin" => "India" }
    )
    product.save!
    attach_placeholder_image!(product, PLACEHOLDER_PALETTE[index % PLACEHOLDER_PALETTE.size])
  end

  puts "  #{category.name}: #{data[:products].size} products"
end

Coupon.find_or_create_by!(code: "WELCOME10") do |c|
  c.discount_type = :percentage
  c.discount_value = 10
  c.min_order_amount = 1000
  c.max_discount_amount = 500
  c.is_active = true
end

Coupon.find_or_create_by!(code: "FLAT500") do |c|
  c.discount_type = :fixed
  c.discount_value = 500
  c.min_order_amount = 3000
  c.is_active = true
end

puts "Seeding complete — #{Category.count} categories, #{Product.count} products, #{Coupon.count} coupons."
