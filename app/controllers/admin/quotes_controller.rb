class Admin::QuotesController < Admin::BaseController
  before_action :set_quote, only: [ :show, :update, :send_quote ]

  def index
    @pagy, @quotes = pagy(Quote.includes(:user).recent, limit: 25)
  end

  def show
    @quote_items = @quote.quote_items.includes(:product)
  end

  def update
    @quote.update(admin_notes: params[:quote][:admin_notes])

    params[:quote][:quote_items_attributes]&.each_value do |attrs|
      item = @quote.quote_items.find(attrs[:id])
      item.update(quoted_unit_price: attrs[:quoted_unit_price]) if attrs[:quoted_unit_price].present?
    end

    redirect_to admin_quote_path(@quote), notice: "Quote updated."
  end

  def send_quote
    if @quote.fully_quoted?
      @quote.update!(status: :quoted, quoted_at: Time.current)
      redirect_to admin_quote_path(@quote), notice: "Quote sent to customer."
    else
      redirect_to admin_quote_path(@quote), alert: "Set a price for every line item before sending."
    end
  end

  private

  def set_quote
    @quote = Quote.find(params[:id])
  end
end
