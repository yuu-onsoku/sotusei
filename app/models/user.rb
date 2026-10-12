class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  AVATAR_MAX_SIZE = 5.megabytes

  has_many :questions, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :diagnoses, dependent: :destroy

  # プロフィールのアイコン（任意）
  has_one_attached :avatar

  # プロフィール項目のバリデーション（email/password は :validatable が担当）
  validates :username, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :name, length: { maximum: 50 }
  validate :acceptable_avatar

  # Google から返ってきた情報で、ログインする人を決める。
  #
  # ⚠️ ここが一番間違えると危ない場所。
  # 「同じメールアドレスなら同じ人」として既存アカウントに紐づける方式を選んだので、
  # そのメールアドレスが本当にその人のものか確かめないと、
  # 他人のメールアドレスを名乗られたときに、そのアカウントに入れてしまう。
  #
  # 紐づけられなかったときは nil を返し、呼び出し側でログイン画面に戻す。
  def self.from_omniauth(auth)
    email = auth.info&.email
    return nil if email.blank?
    return nil unless google_verified_email?(auth)

    # まず uid で探す。2回目以降のログインはここで見つかる。
    # uid は Google 側の識別子で、その人がメールアドレスを変えても変わらない
    found = find_by(provider: auth.provider, uid: auth.uid)
    return found if found

    # 次にメールアドレスで探す。すでにパスワードで登録している人はここで見つかるので、
    # 同じアカウントに Google を紐づける（アカウントが2つに分かれないようにする）
    existing = find_by(email: email)
    if existing
      existing.update(provider: auth.provider, uid: auth.uid)
      return existing
    end

    create_from_omniauth(auth, email)
  end

  # Google は「このメールアドレスは本人のものだと確認済みか」を一緒に返してくる。
  # true と "true" のどちらで来ることもあるので、cast でそろえる
  def self.google_verified_email?(auth)
    ActiveModel::Type::Boolean.new.cast(auth.extra&.raw_info&.email_verified)
  end

  def self.create_from_omniauth(auth, email)
    # auth.info.name ではなく auth.info["name"] を読む。
    # .name は OmniAuth が補完するメソッドで、名前が無いときメールアドレスを返すため、
    # そのまま使うとユーザー名として投稿の横にメールアドレスが公開されてしまう
    display_name = auth.info&.[]("name").to_s

    create(
      email: email,
      # 本人は使わないが、:validatable がパスワードを必須にしているため入れる。
      # 推測できない文字列にしておき、必要ならパスワード再設定から設定してもらう
      password: Devise.friendly_token[0, 24],
      username: unique_username_from(display_name.presence || email.split("@").first),
      name: display_name.first(50),
      provider: auth.provider,
      uid: auth.uid
    )
  end

  # ユーザー名は重複できないので、すでに居たら番号を足す
  def self.unique_username_from(base)
    # 30文字までなので、番号を足す余地を残して切る
    base = base.to_s.strip.first(26).presence || "ねこ好き"
    return base unless exists?(username: base)

    suffix = 2
    suffix += 1 while exists?(username: "#{base}#{suffix}")
    "#{base}#{suffix}"
  end

  private

  # アイコンは形式とサイズを検証（設定していなければ何もしない）
  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.content_type.in?(AVATAR_CONTENT_TYPES)
      errors.add(:avatar, "はPNG / JPEG / GIF / WEBP 形式で添付してください")
    end

    if avatar.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar, "は5MB以下にしてください")
    end
  end
end
