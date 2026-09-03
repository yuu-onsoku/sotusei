require 'rails_helper'
RSpec.describe ApplicationHelper, type: :helper do
 describe "#posted_at" do
  it "「2026年7月21日 14:33」の形式で表示される" do
    time = Time.zone.local(2026, 7, 21, 14, 33)
    expect(helper.posted_at(time)).to eq("2026年7月21日 14:33")
  end

  it "UTCで保存された時刻が日本時間（+9時間）で表示される" do
    question = create(:question, created_at: Time.utc(2026, 7, 21, 5, 33))
    expect(helper.posted_at(question.created_at)).to eq("2026年7月21日 14:33")
  end
  it "1桁の月日にゼロが付かない（7月5日 であって 07月05日 ではない）" do
    time = Time.zone.local(2026, 7, 5, 9, 5)
    expect(helper.posted_at(time)).to eq("2026年7月5日 09:05")
  end
 end
end
