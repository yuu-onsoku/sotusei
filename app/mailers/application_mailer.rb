class ApplicationMailer < ActionMailer::Base
  # 差出人は Devise と同じものを使う（認証済みドメインのアドレス）
  default from: ENV.fetch("MAILER_FROM", "no-reply@nekosyukaijo.com")
  layout "mailer"
end
