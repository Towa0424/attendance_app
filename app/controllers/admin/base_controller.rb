module Admin
  class Admin::BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    private

    def require_admin!
      return if current_user&.admin?
      redirect_to root_path, alert: "権限がありません。"
    end
  end
end
