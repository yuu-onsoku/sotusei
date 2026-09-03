module ApplicationHelper
  def posted_at(time)
    time.strftime("%Y年%-m月%-d日 %H:%M")
  end
end
