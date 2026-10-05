# Resend に API キーを渡す。
# 本番では Render の環境変数 RESEND_API_KEY から読む。
# 開発・テストではメールを実際に送らない（delivery_method が :file / :test）ため、
# キーが無くても動くように fetch の第2引数で空文字を入れておく。
Resend.api_key = ENV.fetch("RESEND_API_KEY", "")
