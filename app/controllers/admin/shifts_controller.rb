module Admin
  class ShiftsController < Admin::BaseController
    before_action :set_groups_and_group!

    def index
      @view_mode = params[:view].in?(%w[month day]) ? params[:view] : "month"

      if @group.nil?
        @users = []
        @shift_patterns = []
        return
      end

      @users = User.where(group_id: @group.id).order(:employee_number, :id)
      @shift_patterns = ShiftPattern.where(group_id: @group.id).order(:id)

      if @view_mode == "day"
        build_day_view
      else
        build_month_view
      end
    end

    # 月別：セルのプルダウン変更で呼ばれる
    # params: shift[user_id], shift[work_date](YYYY-MM-DD), shift[shift_pattern_id](optional)
    def assign
      sp = shift_assign_params
      user = User.find(sp[:user_id])
      work_date = Date.iso8601(sp[:work_date])

      # 未選択（空）なら、その日のシフト自体を削除（= 未設定）
      if sp[:shift_pattern_id].blank?
        Shift.where(user_id: user.id, work_date: work_date).delete_all
        render json: { ok: true, removed: true }
        return
      end

      pattern = ShiftPattern.find(sp[:shift_pattern_id])

      if user.group_id != pattern.group_id
        render json: { ok: false, error: "選択したパターンはユーザーの所属グループと一致しません" }, status: :unprocessable_entity
        return
      end

      Shift.transaction do
        shift = Shift.find_or_initialize_by(user_id: user.id, work_date: work_date)
        shift.apply_pattern!(pattern)
      end

      render json: { ok: true, shift_pattern_id: pattern.id }
    rescue ActionController::ParameterMissing, ArgumentError
      render json: { ok: false, error: "パラメータが不正です" }, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      render json: { ok: false, error: "対象が見つかりません" }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: { ok: false, error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    private

    def shift_assign_params
      params.require(:shift).permit(:user_id, :work_date, :shift_pattern_id)
    end

    def set_groups_and_group!
      @groups = Group.order(:id)
      @group =
        if params[:group_id].present?
          Group.find_by(id: params[:group_id])
        else
          @groups.first
        end
      @group_id = @group&.id
    end

    def build_month_view
      @month = params[:month].present? ? Date.parse(params[:month]).beginning_of_month : Date.current.beginning_of_month
      @days = (@month..@month.end_of_month).to_a

      user_ids = @users.map(&:id)
      @shifts_map =
        Shift.where(group_id: @group.id, user_id: user_ids, work_date: @days)
             .select(:id, :user_id, :work_date, :shift_pattern_id)
             .index_by { |s| [s.user_id, s.work_date] }
    end

    def build_day_view
      @date = params[:date].present? ? Date.parse(params[:date]) : Date.current

      @range_start = @group.work_start_slot
      @range_end = @group.work_end_slot
      @end_on_hour = (@range_end % 4 == 0)

      user_ids = @users.map(&:id)
      shifts =
        Shift.where(group_id: @group.id, user_id: user_ids, work_date: @date)
             .includes(:shift_pattern, shift_details: :time_block)

      @shifts_by_user = shifts.index_by(&:user_id)
      @time_block_map = TimeBlock.all.index_by(&:id)
    end
  end
end
