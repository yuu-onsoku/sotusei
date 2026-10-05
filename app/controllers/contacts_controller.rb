class ContactsController < ApplicationController
  # ログインできない人からの問い合わせを受け取れるよう、ログイン不要にする

  def new
    @contact = Contact.new
    # ログイン中なら返信先を埋めておく
    @contact.email = current_user.email if user_signed_in?
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      # 保存を先に確定させ、通知は裏で送る。
      # 送信に失敗しても問い合わせ自体は失われない。
      ContactMailer.notify(@contact).deliver_later
      redirect_to root_path, notice: "お問い合わせを受け付けました。返信までお時間をいただく場合があります。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :content)
  end
end
