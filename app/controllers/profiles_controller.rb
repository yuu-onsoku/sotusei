class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @form = ProfileForm.from(current_user)
  end

  def update
    @form = ProfileForm.new(profile_params)

    if @form.save
      redirect_to mypage_path, notice: "プロフィールを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # 画面から届いた値に、画面には無い2つ（本人と、外す指示）を足して渡す
  def profile_params
    params.require(:user).permit(:username, :name, :avatar).to_h
          .merge(user: current_user, remove_avatar: params[:remove_avatar])
  end
end
