module Admin
  class TimeOffLocksController < Admin::BaseController
    # PATCH /admin/time_off_locks/toggle
    # params: group_id, month (YYYY-MM)
    def toggle
      group = Group.find(params[:group_id])
      month = Date.strptime(params[:month], "%Y-%m").beginning_of_month

      lock = TimeOffLock.find_or_initialize_by(group_id: group.id, target_month: month)
      lock.locked = !lock.locked
      lock.save!

      render json: { ok: true, locked: lock.locked }
    rescue ArgumentError
      render json: { ok: false, error: "パラメータが不正です" }, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      render json: { ok: false, error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end
end
