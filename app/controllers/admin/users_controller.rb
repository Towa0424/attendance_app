module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: %i[edit update]

    def index
      @groups = Group.order(:name)
      @users = User.includes(:group).order(:employee_number)
      @users = @users.where(group_id: params[:group_id]) if params[:group_id].present?
    end

    def new
      @user = User.new
      load_form_collections
    end

    def create
      @user = User.new(user_params)
      load_form_collections

      if @user.save
        redirect_to admin_users_path, notice: "スタッフを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_collections
    end

    def update
      load_form_collections

      attrs = user_params

      # パスワード未変更なら更新対象から外す（空文字で上書き事故防止）
      if attrs[:password].blank? && attrs[:password_confirmation].blank?
        attrs = attrs.except(:password, :password_confirmation)
      end

      if @user.update(attrs)
        redirect_to admin_users_path, notice: "スタッフ情報を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def load_form_collections
      @groups = Group.order(:name)
    end

    def user_params
      params.require(:user).permit(
        :name,
        :email,
        :employee_number,
        :role,
        :group_id,
        :joined_on,
        :retired_on,
        :employment_type,
        :position,
        :salary_type,
        :salary_amount,
        :password,
        :password_confirmation
      )
    end
  end
end
