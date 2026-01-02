class ApplicationController < ActionController::Base
  # ログイン後は必ず打刻画面へ
  def after_sign_in_path_for(resource)
    time_records_path
  end

  # ログアウト後はログイン画面へ
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
