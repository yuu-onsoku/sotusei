class MypagesController < ApplicationController
  before_action :authenticate_user!

  # 表示するタブ。URLの ?tab= で切り替える
  TABS = %w[questions answers posts bookmarks diagnoses].freeze

  def show
    @tab = TABS.include?(params[:tab]) ? params[:tab] : "questions"

    # 件数はどのタブでも出すので、まとめて数える
    @counts = {
      "questions" => current_user.questions.size,
      "answers" => current_user.answers.size,
      "posts" => current_user.posts.size,
      "bookmarks" => current_user.bookmarks.size,
      "diagnoses" => current_user.diagnoses.size
    }

    @items = items_for(@tab)
  end

  private

  # 選ばれたタブの中身を読み込む。
  # 一覧で出すものを includes しておかないとN+1になる。
  def items_for(tab)
    case tab
    when "questions"
      current_user.questions.includes(:answers, :likes).order(created_at: :desc).page(params[:page])
    when "answers"
      current_user.answers.includes(:question, :likes, image_attachment: :blob).order(created_at: :desc).page(params[:page])
    when "posts"
      current_user.posts.includes(:user, :likes, images_attachments: :blob).order(created_at: :desc).page(params[:page])
    when "bookmarks"
      current_user.bookmarks.includes(bookmarkable: [ :user, :likes, { images_attachments: :blob } ]).order(created_at: :desc).page(params[:page])
    when "diagnoses"
      current_user.diagnoses.order(created_at: :desc).page(params[:page])
    end
  end
end
