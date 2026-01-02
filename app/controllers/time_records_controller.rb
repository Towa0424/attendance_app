class TimeRecordsController < ApplicationController
  before_action :authenticate_user!

  def index
    @today = Date.current
    @today_records = current_user.time_records.where(date: @today).order(:recorded_at)
    @recorded_types = @today_records.map(&:event_type) # 既に打刻済みの種別（ボタン無効化用）
  end

  def create
    event_type = params[:event_type].to_s
    unless TimeRecord.event_types.key?(event_type)
      return redirect_to time_records_path, alert: "不正な打刻種別です。"
    end

    record = current_user.time_records.new(
      date: Date.current,
      event_type: event_type,
      recorded_at: Time.current
    )

    if record.save
      redirect_to time_records_path, notice: "打刻しました（#{helpers.event_type_label(event_type)}）。"
    else
      redirect_to time_records_path, alert: record.errors.full_messages.first || "打刻に失敗しました。"
    end
  end
end

