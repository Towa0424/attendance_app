class TimeOffRequestsController < ApplicationController
  before_action :authenticate_user!

  def index
    # 対象月は翌月のみ
    @month = Date.current.next_month.beginning_of_month
    @days = (@month..@month.end_of_month).to_a

    @requests = current_user.staff_time_off_requests
                            .for_month(@month)
                            .index_by(&:target_date)

    # ロック状態を確認
    @locked = if current_user.group_id.present?
                TimeOffLock.locked?(current_user.group_id, @month)
              else
                false
              end
  end

  # POST /time_off_requests/toggle
  # params: target_date, request_type (preferred / fixed / remove)
  def toggle
    target_date = Date.iso8601(params[:target_date])
    month = Date.current.next_month.beginning_of_month

    # 翌月以外は拒否
    unless target_date.beginning_of_month == month
      render json: { ok: false, error: "翌月分のみ提出可能です" }, status: :unprocessable_entity
      return
    end

    # ロック確認
    if current_user.group_id.present? && TimeOffLock.locked?(current_user.group_id, month)
      render json: { ok: false, error: "この月の希望休はロックされています" }, status: :unprocessable_entity
      return
    end

    existing = current_user.staff_time_off_requests.find_by(target_date: target_date)

    if params[:request_type] == "remove"
      existing&.destroy
      render json: { ok: true, removed: true }
    else
      if existing
        existing.update!(request_type: params[:request_type])
      else
        current_user.staff_time_off_requests.create!(
          target_date: target_date,
          request_type: params[:request_type]
        )
      end
      render json: { ok: true, request_type: params[:request_type] }
    end
  rescue ArgumentError
    render json: { ok: false, error: "日付が不正です" }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { ok: false, error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  end
end
