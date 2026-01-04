module GroupsHelper
  module Admin::GroupsHelper
  def slot_to_time(slot)
    h = slot.to_i / 4
    m = (slot.to_i % 4) * 15
    format("%02d:%02d", h, m)
  end
end

end
