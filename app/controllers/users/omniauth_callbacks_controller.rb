# Googleで認証したあと、Googleから戻ってくる先。
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_omniauth(request.env["omniauth.auth"])

    if user&.persisted?
      # 2つめの引数でフラッシュの文言を Devise に選ばせる（:google_oauth2 の訳を使う）
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      # メールアドレスが取れない、Googleが本人確認済みと言っていない、
      # 保存に失敗した、のいずれか。理由は伏せてログイン画面に戻す
      redirect_to new_user_session_path, alert: "Googleアカウントでのログインができませんでした。お手数ですが、メールアドレスとパスワードでお試しください。"
    end
  end

  # ユーザーがGoogleの画面で「キャンセル」を押した場合など。
  # ここを書いておかないとエラー画面が出てしまう
  def failure
    redirect_to new_user_session_path, alert: "Googleアカウントでのログインを中止しました。"
  end
end
