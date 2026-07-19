class HomeController < ApplicationController
  before_action :authenticate_user!

  # ログイン後のトップページ
  def index
  end
end
