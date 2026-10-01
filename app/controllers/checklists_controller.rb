class ChecklistsController < ApplicationController
  before_action :authenticate_user!

  # チェックリストを表示する
  def new
    @items = ChecklistJudge.items
  end

  # チェックを受け取って結果画面へ移動する
  def create
    session[:checklist_checked] = checked_params
    redirect_to result_checklists_path
  end

  # 結果を表示する
  def result
    checked = session[:checklist_checked]
    return redirect_to new_checklist_path if checked.nil?

    @judge = ChecklistJudge.new(checked)
  end

  private

  # チェックは { "checklist" => { "checked" => ["0", "3"] } } の形で届く
  # checked: [] は「配列を受け取ってよい」という許可の書き方
  def checked_params
    params.fetch(:checklist, {}).permit(checked: [])[:checked] || []
  end
end
