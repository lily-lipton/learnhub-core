# syntax=docker/dockerfile:1
#
# 本番用マルチステージ Dockerfile（Cloud Run デプロイ用）
#
# Stage 1 (frontend-build): React をビルドして静的ファイル (dist/) を生成
# Stage 2 (runtime):        Python イメージに API + 静的ファイルを同梱して起動
#
# 最終イメージに Node.js を含めないことで、サイズと攻撃面を小さく保つ

# ---------------------------------------------------------------------------
# Stage 1: frontend-build — フロントエンドのビルド専用（このステージは最終イメージに残らない）
# ---------------------------------------------------------------------------
FROM node:22-alpine AS frontend-build

WORKDIR /frontend

# package.json だけ先にコピーして npm install → ソース変更時の Docker レイヤキャッシュを効かせる
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm install

# ソース一式をコピーし、本番用静的ファイル (dist/) を生成
COPY frontend/ ./
RUN npm run build

# ---------------------------------------------------------------------------
# Stage 2: runtime — Cloud Run で実際に動かすコンテナ（FastAPI + ビルド済み静的ファイル）
# ---------------------------------------------------------------------------
FROM python:3.14-slim AS runtime

# PYTHONDONTWRITEBYTECODE: .pyc を書かない（イメージを少し小さく）
# PYTHONUNBUFFERED:        ログをバッファせず即 stdout へ（コンテナログで見やすく）
# PORT:                    Cloud Run が待ち受けポートとして渡す（既定 8080）
# APP_ENV:                 本番環境であることを示す（Compose ローカル起動時は上書きされうる）
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    APP_ENV=production

WORKDIR /app

# requirements.txt だけ先にコピー → app 変更時も pip install レイヤをキャッシュ再利用
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# バックエンド API コード
COPY backend/app ./app

# Stage 1 の成果物 (dist/) を static/ に配置 → main.py が SPA + /assets を配信
COPY --from=frontend-build /frontend/dist ./static

EXPOSE 8080

# Cloud Run は PORT 環境変数でポートを指定するため、シェル経由で展開して起動
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]
