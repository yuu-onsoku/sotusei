class ProfileForm
  include ActiveModel::Model

  # 画面にある入力。remove_avatar は DB にないが、フォームには存在する
  attr_accessor :user, :username, :name, :avatar, :remove_avatar

  validate :user_must_be_valid

  def self.from(user)
    # 編集画面を開いたとき、いまの値を入れた受付係を作る
    new(user: user, username: user.username, name: user.name)
  end

  # 項目名の日本語訳は User のものを使う。ja.yml に同じ訳を二重に持たないため
  def self.human_attribute_name(attribute, options = {})
    User.human_attribute_name(attribute, options)
  end

  def save
    assign_to_user
    return false if invalid?
    # 検証を通ってから消す。ここが元のコントローラとの違い
    user.avatar.purge if remove_avatar?
    user.save
  end

  private

  # 預かった値を User に移す。
  # 届かなかった項目（nil）は触らない。update は「送られたキーだけ」書き換えていたので、
  # そこを自分で書くと、送られていない項目まで空にしてしまう。
  def assign_to_user
    user.username = username unless username.nil?
    user.name = name unless name.nil?
    user.avatar = avatar if avatar.present? && !remove_avatar?
  end

  # User 側の検証（username の必須・重複、アイコンの形式とサイズ）を借りてくる。
  # merge! で、User が出したエラーをこのフォームのエラーとして引き継ぐ
  def user_must_be_valid
    errors.merge!(user.errors) if user.invalid?
  end

  # チェックボックスは入っていれば "1" で届く
  def remove_avatar?
    remove_avatar == "1"
  end
end
