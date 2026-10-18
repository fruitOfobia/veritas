# frozen_string_literal: true

require "zlib"
require "net/http"
require "json"

#
# Seed data for Veritas. All names, descriptions and images below are original
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

# --- Real stock photos (Openverse: searches openly-licensed photos, no API key needed) ---
#
# Looks up a real, freely-licensed photo matching `query` and returns its bytes plus
# attribution info, or nil if nothing usable was found (network hiccup, no results,
# dead link, etc). Callers must always have a placeholder fallback — this is
# best-effort, not guaranteed.
STOPWORDS = %w[with for and the a an of].freeze

# How many of the query's meaningful words show up in a result's title/tags —
# used to reject photos that only matched on a loose/unrelated tag (e.g. a search
# for "floor tile" turning up a decorative door because someone tagged it "tile").
def match_score(query, result)
  words = query.downcase.split(/\s+/) - STOPWORDS
  haystack = ([ result["title"] ] + Array(result["tags"]).map { |t| t["name"] }).compact.join(" ").downcase
  matches = words.count { |w| haystack.include?(w) }
  [ matches, words.size ]
end

def fetch_stock_photo(query)
  search_uri = URI("https://api.openverse.org/v1/images/")
  search_uri.query = URI.encode_www_form(
    q: query, license_type: "commercial", mature: "false", page_size: 20
  )

  response = http_get(search_uri)
  return nil unless response.is_a?(Net::HTTPSuccess)

  results = JSON.parse(response.body)["results"] || []

  # Require every meaningful query word to appear in the title/tags — strict, but
  # that's the point: a wrong photo is worse than a clean placeholder tile.
  candidates = results.select do |result|
    matches, total = match_score(query, result)
    total.positive? && matches == total
  end
  candidates = candidates.sort_by { |r| -r["title"].to_s.length } # prefer more specific titles

  candidates.each do |result|
    image_uri = begin
      URI(result["url"])
    rescue StandardError
      next
    end
    image_response = http_get(image_uri)
    next unless image_response.is_a?(Net::HTTPSuccess)

    content_type = image_response.content_type.to_s
    next unless content_type.start_with?("image/")

    body = image_response.body
    next if body.nil? || body.bytesize < 3_000 || body.bytesize > 8_000_000

    return {
      body: body,
      content_type: content_type,
      creator: result["creator"].presence || "Unknown",
      license: result["license"].to_s.upcase,
      source_url: result["foreign_landing_url"]
    }
  end

  nil
rescue StandardError => e
  Rails.logger.warn("[seeds] stock photo lookup failed for #{query.inspect}: #{e.class} #{e.message}")
  nil
end

# Follows up to 5 redirects. Returns the final Net::HTTPResponse (or the last redirect
# response if the limit is hit).
def http_get(uri, limit: 5)
  return nil if limit.zero?

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  http.open_timeout = 8
  http.read_timeout = 12

  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = "VeritasSeed/1.0 (+https://example.com)"
  response = http.request(request)

  case response
  when Net::HTTPRedirection
    http_get(URI(response["location"]), limit: limit - 1)
  else
    response
  end
end

def extension_for(content_type)
  { "image/jpeg" => "jpg", "image/png" => "png", "image/webp" => "webp", "image/gif" => "gif" }
    .fetch(content_type, "jpg")
end

def attach_photo!(product, query, fallback_rgb)
  return if product.images.attached?

  photo = fetch_stock_photo(query)

  if photo
    product.images.attach(
      io: StringIO.new(photo[:body]),
      filename: "#{product.slug}.#{extension_for(photo[:content_type])}",
      content_type: photo[:content_type]
    )
    product.update_column(
      :specifications,
      product.specifications.merge(
        "Photo Credit" => "#{photo[:creator]} — #{photo[:license]} (via Openverse#{", #{photo[:source_url]}" if photo[:source_url]})"
      )
    )
    print "."
  else
    attach_placeholder_image!(product, fallback_rgb)
    print "x"
  end
end

puts "Seeding Veritas…"

ActiveRecord::Base.transaction do
  admin = User.find_or_initialize_by(email: "admin@veritas.test")
  admin.assign_attributes(
    password: "password123",
    password_confirmation: "password123",
    first_name: "Store",
    last_name: "Admin",
    role: :admin
  )
  admin.save!

  demo = User.find_or_initialize_by(email: "demo@veritas.test")
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
      { name: "Quartz Kitchen Countertop Slab", unit: "sq.ft", price: 1450, mrp: 1800, photo: "quartz kitchen countertop" },
      { name: "Stainless Steel Double Bowl Sink", unit: "piece", price: 3200, mrp: 3900, photo: "stainless steel kitchen sink" },
      { name: "High-Gloss Kitchen Laminate Sheet", unit: "sheet", price: 2100, mrp: nil, photo: "glossy laminate sheet" },
      { name: "Soft-Close Kitchen Cabinet Hinges (Pack of 10)", unit: "pack", price: 850, mrp: 999, photo: "cabinet hinge hardware" },
      { name: "Modular Kitchen Basket Set", unit: "set", price: 4500, mrp: 5200, photo: "kitchen cabinet pull out basket" }
    ]
  },
  "Bathroom" => {
    desc: "Basins, faucets, tiles and accessories for every bathroom.",
    products: [
      { name: "Ceramic Wall-Mounted Wash Basin", unit: "piece", price: 2800, mrp: 3400, photo: "ceramic wash basin bathroom" },
      { name: "Single Lever Basin Mixer Faucet", unit: "piece", price: 1650, mrp: 1950, photo: "chrome basin mixer faucet" },
      { name: "Anti-Skid Bathroom Floor Tile 300x300mm", unit: "sq.ft", price: 65, mrp: 85, photo: "bathroom floor tile" },
      { name: "Rain Shower Head with Arm", unit: "set", price: 2200, mrp: nil, photo: "rain shower head" }
    ]
  },
  "Wardrobe" => {
    desc: "Laminates, hardware and fittings for custom wardrobes.",
    products: [
      { name: "Matte-Finish Wardrobe Laminate Sheet", unit: "sheet", price: 1900, mrp: 2300, photo: "matte laminate sheet wood" },
      { name: "Wardrobe Sliding Door Track Set", unit: "set", price: 3100, mrp: nil, photo: "sliding wardrobe door track" },
      { name: "Wardrobe Drawer Channel 18-inch", unit: "pair", price: 420, mrp: 500, photo: "drawer slide channel hardware" }
    ]
  },
  "Hardware" => {
    desc: "Handles, locks, hinges and fasteners for every part of the home.",
    products: [
      { name: "Stainless Steel Door Handle Set", unit: "set", price: 950, mrp: 1150, photo: "stainless steel door handle" },
      { name: "Heavy Duty Cabinet Lock", unit: "piece", price: 380, mrp: nil, photo: "cabinet lock hardware" },
      { name: "Concealed Door Hinge (Pack of 4)", unit: "pack", price: 560, mrp: 650, photo: "door hinge hardware" }
    ]
  },
  "Electrical" => {
    desc: "Wires, switches, lighting and fans for safe, modern wiring.",
    products: [
      { name: "Modular Switch Plate (4-Way)", unit: "piece", price: 320, mrp: 380, photo: "electrical switch plate" },
      { name: "1.5 Sq.mm Copper Wire (90m Coil)", unit: "coil", price: 2450, mrp: 2750, photo: "electrical copper wire coil" },
      { name: "LED Ceiling Light Panel 24W", unit: "piece", price: 780, mrp: 950, photo: "led ceiling light panel" },
      { name: "Energy-Efficient Ceiling Fan", unit: "piece", price: 2600, mrp: 3100, photo: "ceiling fan" }
    ]
  },
  "Plumbing" => {
    desc: "Pipes, valves and fittings for reliable water supply and drainage.",
    products: [
      { name: "CPVC Plumbing Pipe 1-inch (3m)", unit: "piece", price: 340, mrp: nil, photo: "cpvc plumbing pipe" },
      { name: "Brass Gate Valve 1/2-inch", unit: "piece", price: 480, mrp: 560, photo: "brass gate valve plumbing" },
      { name: "PVC Drainage Elbow Fitting", unit: "piece", price: 95, mrp: nil, photo: "pvc pipe elbow fitting" }
    ]
  },
  "Flooring" => {
    desc: "Tiles, wooden flooring and waterproofing for every surface.",
    products: [
      { name: "Vitrified Floor Tile 600x600mm", unit: "sq.ft", price: 72, mrp: 95, photo: "vitrified floor tile" },
      { name: "Laminate Wooden Flooring Plank", unit: "sq.ft", price: 110, mrp: 135, photo: "laminate wood flooring" },
      { name: "Waterproofing Membrane Coating (20L)", unit: "drum", price: 3800, mrp: 4200, photo: "waterproofing coating drum" }
    ]
  },
  "Wall Finishes" => {
    desc: "Paints, putty, plywood and wallpaper for interior and exterior walls.",
    products: [
      { name: "Interior Emulsion Paint (20L)", unit: "drum", price: 4200, mrp: 4800, photo: "paint bucket interior wall" },
      { name: "Wall Putty (40kg Bag)", unit: "bag", price: 950, mrp: nil, photo: "wall putty bag cement" },
      { name: "Waterproof Plywood Sheet 19mm", unit: "sheet", price: 3600, mrp: 4100, photo: "plywood sheet stack" },
      { name: "Textured Wallpaper Roll", unit: "roll", price: 1450, mrp: 1700, photo: "textured wallpaper roll" }
    ]
  },
  "Adhesives & Sealants" => {
    desc: "Tile adhesives, silicone sealants and bonding solutions.",
    products: [
      { name: "Tile Adhesive (20kg Bag)", unit: "bag", price: 620, mrp: nil, photo: "tile adhesive bag" },
      { name: "Silicone Sealant Cartridge", unit: "piece", price: 280, mrp: 330, photo: "silicone sealant cartridge tube" }
    ]
  },
  "Blinds & Window Treatments" => {
    desc: "Roller blinds, curtains and window fittings.",
    products: [
      { name: "Roller Blind - Blackout Fabric", unit: "sq.ft", price: 180, mrp: 220, photo: "roller blind window" },
      { name: "Vertical Blind Track System", unit: "set", price: 1350, mrp: nil, photo: "vertical blinds window" }
    ]
  },
  "Building Materials" => {
    desc: "Cement, steel, sand and core construction materials.",
    products: [
      { name: "OPC 53 Grade Cement (50kg Bag)", unit: "bag", price: 420, mrp: nil, photo: "cement bags construction" },
      { name: "TMT Steel Reinforcement Bar 12mm", unit: "quintal", price: 5800, mrp: 6100, photo: "steel rebar reinforcement" },
      { name: "Red Clay Building Brick (Per 1000)", unit: "lot", price: 7200, mrp: nil, photo: "red clay bricks stack" }
    ]
  },
  "Tool Rentals" => {
    desc: "Power tools and equipment available for short-term rental.",
    products: [
      { name: "Rotary Hammer Drill (Daily Rental)", unit: "day", price: 450, mrp: nil, photo: "rotary hammer drill tool" },
      { name: "Concrete Mixer (Daily Rental)", unit: "day", price: 1200, mrp: nil, photo: "concrete mixer machine" },
      { name: "Tile Cutter Machine (Daily Rental)", unit: "day", price: 650, mrp: nil, photo: "tile cutter machine" }
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
      specifications: { "Brand" => "Veritas Select", "Warranty" => "6 months", "Origin" => "India" }
    )
    product.save!
    attach_photo!(product, product_attrs[:photo] || product_attrs[:name], PLACEHOLDER_PALETTE[index % PLACEHOLDER_PALETTE.size])
  end

  puts
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
