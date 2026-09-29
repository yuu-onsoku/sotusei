class HomeController < ApplicationController
  # トップページは未ログインでも開ける（診断への入口のため）
  before_action :authenticate_user!, except: :index

  # ログイン済みならコミュニティのトップ、未ログインならランディングページ
  def index
    render :landing unless user_signed_in?
  end
end
