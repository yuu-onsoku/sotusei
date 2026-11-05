require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    #
    # gem は 8.1 に上げているが、ここは 8.0 のままにしている（2026-11-05）。
    # 「gem を上げること」と「フレームワークの既定の挙動を変えること」は別の作業で、
    # 両方いっぺんにやると、壊れたときにどちらが原因か分からなくなるため。
    #
    # 今回の目的は Rails 8.0 のサポート終了（2026-11-07）から離れることで、
    # それは gem を上げた時点で達成している。
    # 8.1 の既定に移すときは、変わる項目を1つずつ確かめてから上げる（#107）
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # 投稿時刻などを日本時間で表示する（本番サーバーのタイムゾーンはUTCのため）
    config.time_zone = "Tokyo"

    # エラーメッセージなどを日本語で表示する
    config.i18n.default_locale = :ja
    config.i18n.available_locales = %i[ja en]
    # config.eager_load_paths << Rails.root.join("extras")
    # rails g model などでテストファイルをRSpec（spec/）側に生成する
    config.generators do |g|
      g.test_framework :rspec, fixture: false
    end
  end
end
