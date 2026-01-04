module Admin
  class TimeBlocksController < Admin::BaseController
    before_action :set_time_block, only: %i[edit update]

    def index
      @time_blocks = TimeBlock.order(:name)
    end

    def new
      @time_block = TimeBlock.new(color_code: "#3b82f6", has_cost: true, has_sales: true)
    end

    def create
      @time_block = TimeBlock.new(time_block_params)
      if @time_block.save
        redirect_to admin_time_blocks_path, notice: "時間ブロックを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @time_block.update(time_block_params)
        redirect_to admin_time_blocks_path, notice: "時間ブロックを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_time_block
      @time_block = TimeBlock.find(params[:id])
    end

    def time_block_params
      params.require(:time_block).permit(:name, :color_code, :has_cost, :has_sales)
    end
  end
end
