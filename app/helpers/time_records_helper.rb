module TimeRecordsHelper
  def event_type_label(key)
    {
      "clock_in" => "出勤",
      "clock_out" => "退勤",
      "break_start" => "休始",
      "break_end" => "休終"
    }[key.to_s] || key.to_s
  end
end
