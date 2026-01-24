class ShiftsController < ApplicationController
  before_action :authenticate_user!

  def index
    @month = parse_month(params[:month])
    return if performed?
    range = @month.beginning_of_month..@month.end_of_month

    @days = range.to_a

    shifts = current_user.shifts
                         .includes(shift_pattern: { shift_pattern_details: :time_block })
                         .where(work_date: range)
    @shift_map = shifts.index_by(&:work_date)

    @time_records_map = current_user.time_records
                                    .where(date: range)
                                    .order(:recorded_at)
                                    .group_by(&:date)
  end

  private

  def parse_month(raw)
    return Date.current if raw.blank?

    Date.strptime(raw, "%Y-%m")
  rescue ArgumentError
    redirect_to shifts_path, alert: "月の指定が不正です。"
    nil
  end
end