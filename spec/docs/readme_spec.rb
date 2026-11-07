require 'rails_helper'

# README に書いた数字が、実装とずれていないかを確かめる。
#
# 「診断が15問・18点のままで、実装（20問・24点）と食い違っている」という指摘を受けて書いた。
# 数字を README から消す手もあったが、読む人には数があったほうが親切なので、
# 数字は残したうえで、ずれたらここで落ちるようにしている。
#
# リンクが繋がっていることをリクエストspecで固定したのと同じ考え方で、
# 気をつけて防ぐのではなく、間違えたら気づける形にする。
RSpec.describe "README" do
  let(:readme) { Rails.root.join("README.md").read }

  describe "お迎え診断" do
    it "簡易診断の問題数が実装と一致している" do
      expect(readme).to include("簡易・#{DiagnosisJudge.simple_questions.size}問")
    end

    it "詳細診断の問題数が実装と一致している" do
      expect(readme).to include("詳細・#{DiagnosisJudge.full_questions.size}問")
    end

    it "追加した問題数が実装と一致している" do
      added = DiagnosisJudge.full_questions.size - DiagnosisJudge.simple_questions.size

      expect(readme).to include("についての#{added}問を加えた")
    end

    # 境目は「満点の割合」で決まるので、満点が変われば境目も変わる。
    # README では、その仕組みの説明として具体的な数字を出している
    it "満点と判定の境目が実装と一致している" do
      simple_max = DiagnosisJudge.new({}).max_score
      full_max = DiagnosisJudge.new({}, kind: :full).max_score
      border = (full_max * DiagnosisJudge::READY_RATIO).to_i

      expect(readme).to include("満点#{simple_max}点")
      expect(readme).to include("満点#{full_max}点")
      expect(readme).to include("境目は#{(simple_max * DiagnosisJudge::READY_RATIO).to_i}点から#{border}点へ")
    end
  end

  describe "覚悟のチェックリスト" do
    it "項目数が実装と一致している" do
      expect(readme).to include("#{ChecklistJudge.items.size}項目")
    end
  end

  describe "ER図" do
    it "diagnoses の kind の説明が実装と一致している" do
      expect(readme).to include("simple（簡易診断・#{DiagnosisJudge.simple_questions.size}問）")
      expect(readme).to include("full（詳細診断・#{DiagnosisJudge.full_questions.size}問）")
    end

    # 10/13 に diagnoses.kind を足したとき、ER図に書き忘れていた
    it "すべてのテーブルが載っている" do
      tables = ActiveRecord::Base.connection.tables -
               %w[schema_migrations ar_internal_metadata] -
               ActiveRecord::Base.connection.tables.grep(/^active_storage_/)

      tables.each do |table|
        expect(readme).to include("    #{table} {"), "ER図に #{table} がありません"
      end
    end
  end

  describe "技術スタック" do
    it "Ruby と Rails の版が実装と一致している" do
      expect(readme).to include("Ruby #{RUBY_VERSION}")
      expect(readme).to include("Rails #{Rails.version.split('.').first(2).join('.')}")
    end
  end
end
