# 🏗️ Veritas — Building & Interior Materials, Delivered

A full-featured e-commerce application for construction, interior and building materials, built
with Ruby on Rails 8.1 and Ruby 3.2.2. Inspired by the feature set of retailers like
[buildingsteps.com](https://www.buildingsteps.com) — category-first shopping, cart & wishlist,
and a B2B **Request a Quote** flow for contractors and designers — with an original design and
placeholder catalog content.

---

## ✨ Features

### 👤 Accounts
- Email/password authentication via Devise (customer & admin roles)
- Optional company name / GSTIN fields for trade customers
- Address book with a default delivery address

### 🛒 Shopping
- Multi-level category tree (Kitchen, Bathroom, Wardrobe, Hardware, Electrical, Plumbing,
  Flooring, Wall Finishes, Adhesives & Sealants, Blinds, Building Materials, Tool Rentals)
- Product listing with search, category/price filters and sorting
- Product detail pages with image gallery, specifications, and reviews
- Cart and wishlist
- Coupon codes (percentage or fixed discount)
- Checkout with Cash on Delivery or Razorpay (test mode)

### 📋 Request a Quote (B2B)
- Customers submit multi-line quote requests for bulk pricing
- Admin reviews the request and sets a price per line item
- Customer accepts the priced quote, which converts straight into an order

### 👨‍💼 Admin Dashboard
- Revenue/orders charts (Chartkick + Groupdate), low-stock alerts
- Manage categories, products (with image uploads), orders, quotes, coupons and users

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Rails 8.1, Ruby 3.2.2 |
| Database | PostgreSQL |
| Frontend | Turbo, Stimulus, Tailwind CSS v4, esbuild |
| Auth | Devise |
| Pagination | Pagy |
| Charts | Chartkick + Groupdate |
| Payments | Razorpay (test mode) + Cash on Delivery |
| Background jobs | Solid Queue |
| Testing | RSpec, FactoryBot, Faker, Shoulda Matchers |
| Deployment | Kamal + Docker |

---

## 🚀 Getting Started

```bash
bundle install
yarn install
bin/rails db:create db:migrate db:seed
bin/dev
```

`bin/dev` boots Puma plus the esbuild and Tailwind watchers (via `Procfile.dev` / foreman).

Visit `http://localhost:3000`.

Seeded accounts (password for both: `password123`):

| Role | Email |
|---|---|
| Admin | `admin@veritas.test` |
| Customer | `demo@veritas.test` |

## 🧪 Testing

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman
```

## 📂 Application Structure

- `app/models` — `User`, `Category` (self-referential tree), `Product`, `Cart`/`CartItem`,
  `Wishlist`/`WishlistItem`, `Order`/`OrderItem`/`Payment`, `Coupon`, `ProductReview`,
  `Quote`/`QuoteItem`
- `app/controllers` — public storefront controllers plus an `admin/` namespace gated by
  `Admin::BaseController#require_admin!`
- `app/views/shared` — reusable partials (`_header`, `_footer`, `_product_card`, `_pagination`, …)
- `db/seeds.rb` — original placeholder categories/products (not scraped from any real retailer)

## ⚙️ Configuration

Copy `.env` values as needed for Razorpay test keys:

```
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
```

Active Storage uses local disk in development/test; configure `config/storage.yml` for S3 in
production.
