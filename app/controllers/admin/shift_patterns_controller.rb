module Admin
  class ShiftPatternsController < Admin::BaseController
    before_action :set_shift_pattern, only: %i[edit update]

    def index
    @groups = Group.order(:id)
    @group_id = params[:group_id].presence

    scope = ShiftPattern
      .includes(:group, shift_pattern_details: :time_block)
      .order(:id)

    scope = scope.where(group_id: @group_id) if @group_id

    @shift_patterns = scope

    # time_block_id => TimeBlock の参照（Viewでブロック色を引く）
    @time_block_map = TimeBlock.all.index_by(&:id)

    # 画面上部の「表示時間」は、グループで絞り込んだ時だけ出す（全て表示時は各行が別レンジのため）
    if @group_id
      g = @groups.find { |x| x.id == @group_id.to_i }
      @header_range_start = g&.work_start_slot
      @header_range_end   = g&.work_end_slot
    else
      @header_range_start = nil
      @header_range_end   = nil
    end
  end

    def new
      build_form_resources
      @shift_pattern = ShiftPattern.new
      @slots = Array.new(ShiftPattern::SLOTS_PER_DAY, nil)
    end

    def create
      build_form_resources
      @shift_pattern = ShiftPattern.new(shift_pattern_params)

      ActiveRecord::Base.transaction do
        @shift_pattern.save!
        persist_slots!(@shift_pattern, parsed_slots)
      end

      redirect_to admin_shift_patterns_path, notice: "シフトパターンを作成しました。"
    rescue ActiveRecord::RecordInvalid
      @slots = parsed_slots
      render :new, status: :unprocessable_entity
    end

    def edit
      build_form_resources
      @slots = @shift_pattern.slots_array
    end

    def update
      build_form_resources

      ActiveRecord::Base.transaction do
        @shift_pattern.update!(shift_pattern_params)
        persist_slots!(@shift_pattern, parsed_slots)
      end

      redirect_to admin_shift_patterns_path(group_id: params[:group_id]), notice: "シフトパターンを更新しました。"
    rescue ActiveRecord::RecordInvalid
      @slots = parsed_slots
      render :edit, status: :unprocessable_entity
    end

    private

    def set_shift_pattern
      @shift_pattern = ShiftPattern.includes(shift_pattern_details: :time_block).find(params[:id])
    end

    def shift_pattern_params
      params.require(:shift_pattern).permit(:name, :group_id)
    end

    # transportはJSONだが、DBはslotテーブルへ
    def parsed_slots
      raw = params.dig(:shift_pattern, :slots_json).to_s
      arr = JSON.parse(raw)
      arr = Array(arr)

      slots = Array.new(ShiftPattern::SLOTS_PER_DAY, nil)
      arr.take(ShiftPattern::SLOTS_PER_DAY).each_with_index do |v, i|
        slots[i] = v.present? ? v.to_i : nil
      end
      slots
    rescue JSON::ParserError
      Array.new(ShiftPattern::SLOTS_PER_DAY, nil)
    end

    # nilは削除、idありは更新/作成
    def persist_slots!(shift_pattern, slots)
      existing = shift_pattern.shift_pattern_details.index_by(&:slot_index)
      keep = []

      slots.each_with_index do |time_block_id, slot_index|
        next if time_block_id.nil?

        keep << slot_index
        if existing[slot_index]
          existing[slot_index].update!(time_block_id: time_block_id)
        else
          shift_pattern.shift_pattern_details.create!(slot_index: slot_index, time_block_id: time_block_id)
        end
      end

      if keep.empty?
        shift_pattern.shift_pattern_details.delete_all
      else
        shift_pattern.shift_pattern_details.where.not(slot_index: keep).delete_all
      end
    end

    # グループごとの「表示レンジ」を既存パターンから推定（無ければ 09:00-20:00）
    def build_form_resources
      @groups = Group.order(:id)
      @time_blocks = TimeBlock.order(:id)

      stats = ShiftPatternDetail.joins(:shift_pattern)
                                .group("shift_patterns.group_id")
                                .pluck("shift_patterns.group_id", "MIN(slot_index)", "MAX(slot_index)")

      @group_ranges = {}
      stats.each do |group_id, min_slot, max_slot|
        start_slot = (min_slot / 4) * 4
        end_excl   = max_slot + 1
        end_slot   = ((end_excl + 3) / 4) * 4
        end_slot = [end_slot, ShiftPattern::SLOTS_PER_DAY].min
        @group_ranges[group_id] = { start: start_slot, end: end_slot }
      end

      @groups.each do |g|
        @group_ranges[g.id] ||= { start: ShiftPattern::DEFAULT_START_SLOT, end: ShiftPattern::DEFAULT_END_SLOT }
      end
    end
    def details
      sp = ShiftPattern.find(params[:id])
      details = sp.shift_pattern_details.map do |d|
        {
          start: d.start_slot,
          end: d.end_slot,
          kind: d.kind
        }
      end
      render json: details
    end
  end
end
