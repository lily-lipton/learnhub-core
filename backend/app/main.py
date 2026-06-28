import os
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

app = FastAPI(title="learnhub-core", version="0.1.0")

STATIC_DIR = Path(__file__).resolve().parent.parent / "static"


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/hello")
def hello() -> dict[str, str]:
    return {
        "message": "Hello from learnhub-core",
        "environment": os.getenv("APP_ENV", "development"),
    }


# backend/static/ が存在する場合のみ、本番向けの静的ファイル配信を有効化する
# 開発時は backend/static/ はコンテナ内にマウントされない
if STATIC_DIR.is_dir():
    # Vite ビルドの JS/CSS 等（/assets/*）を専用マウントで高速に配信する
    # index.html 内の <script src="/assets/..."> がここにマッチする
    app.mount("/assets", StaticFiles(directory=STATIC_DIR / "assets"), name="assets")

    # 上記以外のパスはキャッチオールで受け取り、SPA のルーティングを担う
    @app.get("/{full_path:path}")
    def serve_spa(full_path: str) -> FileResponse:
        if full_path.startswith("api/"):
            raise HTTPException(status_code=404, detail="Not found")

        index_path = STATIC_DIR / "index.html"
        if not index_path.is_file():
            raise HTTPException(status_code=404, detail="Frontend build not found")

        requested = STATIC_DIR / full_path
        # favicon.ico など、実在する静的ファイルはそのまま返す
        if full_path and requested.is_file():
            return FileResponse(requested)

        return FileResponse(index_path)
