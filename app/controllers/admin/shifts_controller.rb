module Admin
  class ShiftsController < Admin::BaseController
    before_action :set_groups_and_group!

    def index
      @view_mode = params[:view].in?(%w[month day]) ? params[:view] : "month"

      if @group.nil?
        # グループ未作成など
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
    # params: user_id, work_date(YYYY-MM-DD), shift_pattern_id(optional)
    def assign
      user = User.find(params[:user_id])
      work_date = Date.iso8601(params[:work_date])

      # 未選択（空）なら、その日のシフト自体を削除（= 未設定）
      if params[:shift_pattern_id].blank?
        Shift.where(user_id: user.id, work_date: work_date).delete_all
        render json: { ok: true, removed: true, slots: Array.new(ShiftPattern::SLOTS_PER_DAY, nil) }
        return
      end

      pattern = ShiftPattern.find(params[:shift_pattern_id])

      # 安全：所属グループが一致しない更新は弾く（要件「出てくるパターンは所属グループに依存」前提）
      if user.group_id != pattern.group_id
        render json: { ok: false, error: "所属グループと一致しないパターンは設定できません" },
               status: :unprocessable_entity
        return
      end

      shift = nil

      Shift.transaction do
        shift = Shift.find_or_initialize_by(user_id: user.id, work_date: work_date)
        shift.apply_pattern!(pattern)
      end

      shift.reload

      render json: { ok: true, shift_pattern_id: pattern.id, slots: shift.slots_array }
    rescue ArgumentError
      render json: { ok: false, error: "日付が不正です" }, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      render json: { ok: false, error: e.record.errors.full_messages.join(", ") },
             status: :unprocessable_entity
    end

    # 日別：ガント編集内容の保存
    # params: user_id, work_date(YYYY-MM-DD), slots(array[96])
    def update_details
      user = User.find(params[:user_id])
      work_date = Date.iso8601(params[:work_date])

      shift = Shift.find_by(user_id: user.id, work_date: work_date)
      unless shift
        render json: { ok: false, error: "シフトが見つかりません" }, status: :not_found
        return
      end

      slots =
        case params[:slots]
        when Array
          params[:slots]
        when ActionController::Parameters
          params[:slots]
            .to_unsafe_h
            .sort_by { |k, _| k.to_i }
            .map { |_, v| v }
        else
          []
        end
        
      if slots.is_a?(Array) && slots.length != ShiftPattern::SLOTS_PER_DAY
        group = shift.group
        range_length = group.present? ? group.work_end_slot - group.work_start_slot : nil
        if range_length.present? && slots.length == range_length
          normalized = Array.new(ShiftPattern::SLOTS_PER_DAY, nil)
          slots.each_with_index do |val, idx|
            normalized[group.work_start_slot + idx] = val
          end
          slots = normalized
        end
      end

      unless slots.is_a?(Array) && slots.length == ShiftPattern::SLOTS_PER_DAY
        render json: { ok: false, error: "スロットが不正です" }, status: :unprocessable_entity
        return
      end

      now = Time.current
      rows = []

      slots.each_with_index do |tb_id, idx|
        next if tb_id.blank?

        rows << {
          shift_id: shift.id,
          slot_index: idx,
          time_block_id: tb_id.to_i,
          created_at: now,
          updated_at: now
        }
      end

      ShiftDetail.transaction do
        shift.shift_details.delete_all
        ShiftDetail.insert_all(rows) if rows.present?
      end

      render json: { ok: true }
    rescue ArgumentError
      render json: { ok: false, error: "日付が不正です" }, status: :unprocessable_entity
    end

    private

    def set_groups_and_group!
      @groups = Group.order(:id)
      @group =
        if params[:group_id].present?
          @groups.find { |g| g.id == params[:group_id].to_i }
        else
          @groups.first
        end
      @group_id = @group&.id
    end

    def build_month_view
      base =
        if params[:month].present?
          Date.strptime(params[:month], "%Y-%m").beginning_of_month
        else
          Date.current.beginning_of_month
        end

      @month = base
      @days = (@month.beginning_of_month..@month.end_of_month).to_a

      shifts = Shift.where(group_id: @group.id, work_date: @days).select(:id, :user_id, :work_date, :shift_pattern_id)
      @shifts_map = shifts.index_by { |s| [s.user_id, s.work_date] }
    rescue ArgumentError
      @month = Date.current.beginning_of_month
      @days = (@month.beginning_of_month..@month.end_of_month).to_a
      @shifts_map = {}
    end

    def build_day_view
      @date =
        if params[:date].present?
          Date.iso8601(params[:date])
        else
          Date.current
        end

      @range_start = @group.work_start_slot
      @range_end   = @group.work_end_slot
      @end_on_hour = (@range_end % 4 == 0)

      shifts = Shift.where(group_id: @group.id, work_date: @date)
              .includes(:shift_pattern, shift_details: :time_block)

      @shifts_by_user = shifts.index_by(&:user_id)
      @time_blocks = TimeBlock.order(:id)
      @time_block_map = @time_blocks.index_by(&:id)
    rescue ArgumentError
      @date = Date.current
      @range_start = @group.work_start_slot
      @range_end   = @group.work_end_slot
      @end_on_hour = (@range_end % 4 == 0)
      @shifts_by_user = {}
      @time_blocks = TimeBlock.order(:id)
      @time_block_map = @time_blocks.index_by(&:id)
    end
  end
end
