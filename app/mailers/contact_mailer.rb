class ContactMailer < ApplicationMailer
  # お問い合わせが届いたことを運営者に知らせる。
  # 宛先はリポジトリに個人のアドレスを残さないよう環境変数で渡す。
  def notify(contact)
    @contact = contact

    mail(
      to: ENV.fetch("ADMIN_EMAIL", "admin@nekosyukaijo.com"),
      # 受け取ったメールにそのまま返信すれば、問い合わせた人に届く
      reply_to: contact.email,
      subject: "【ねこの集会場】お問い合わせが届きました"
    )
  end
end
