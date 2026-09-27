class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :update ]

  def index
    @pagy, @users = pagy(User.order(created_at: :desc), limit: 25)
  end

  def show
    @orders = @user.orders.recent
    @quotes = @user.quotes.recent
  end

  def update
    if @user.update(role: params[:user][:role])
      redirect_to admin_user_path(@user), notice: "User updated."
    else
      redirect_to admin_user_path(@user), alert: @user.errors.full_messages.to_sentence
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
