module Admin
  class GroupsController < Admin::BaseController
    before_action :set_group, only: %i[edit update]

    def index
      @groups = Group.includes(:users).order(:name)
    end

    def new
      @group = Group.new(work_start_slot: 36, work_end_slot: 72) # 9:00〜18:00
    end

    def create
      @group = Group.new(group_params)

      if @group.save
        redirect_to admin_groups_path, notice: "グループを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @group.update(group_params)
        redirect_to admin_groups_path, notice: "グループを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_group
      @group = Group.find(params[:id])
    end

    def group_params
      params.require(:group).permit(:name, :work_start_slot, :work_end_slot)
    end

  end
end
