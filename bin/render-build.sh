#!/usr/bin/env bash
# Render のビルドコマンドから呼ばれるスクリプト。
# ダッシュボードの Build Command に「./bin/render-build.sh」を設定する。
#
# 途中で失敗したらそこで止める（失敗に気づかずデプロイされるのを防ぐ）
set -o errexit

bundle install

# JS / CSS のビルド（jsbundling-rails, cssbundling-rails が yarn を呼ぶ）
yarn install --frozen-lockfile

bundle exec rails assets:precompile
bundle exec rails assets:clean

# 無料プランでは pre-deploy command が使えないため、ここでマイグレーションを流す
bundle exec rails db:migrate
