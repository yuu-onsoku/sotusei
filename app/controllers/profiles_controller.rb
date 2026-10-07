class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    # アイコンを外す指示があれば先に外す
    @user.avatar.purge if params[:remove_avatar] == "1"

    if @user.update(profile_params)
      redirect_to mypage_path, notice: "プロフィールを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # ファイルを選ばずに送ると avatar が "" で届くので、そのときは渡さない
  def profile_params
    permitted = params.require(:user).permit(:username, :name, :avatar)
    permitted.delete(:avatar) if permitted[:avatar].blank?
    permitted
  end
end
