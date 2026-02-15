module Admin
  class TimeOffLocksController < Admin::BaseController
    def toggle
      group_id = params[:group_id]
      month = Date.strptime(params[:month], "%Y-%m").beginning_of_month

      lock = TimeOffLock.find_or_initialize_by(group_id: group_id, target_month: month)
      lock.locked = !lock.locked
      lock.save!

      render json: { ok: true, locked: lock.locked }
    rescue ArgumentError
      render json: { ok: false, error: "パラメータが不正です" }, status: :unprocessable_entity
    end
  end
end
