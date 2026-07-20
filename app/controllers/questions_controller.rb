class QuestionsController < ApplicationController
  before_action :authenticate_user!

  # ねこの相談室（質問一覧）。現状はUIのみ。
  def index
  end
end
