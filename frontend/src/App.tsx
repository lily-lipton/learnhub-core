import { useEffect, useState } from "react";
import "./App.css";

type HelloResponse = {
  message: string;
  environment: string;
};

export default function App() {
  const [data, setData] = useState<HelloResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/hello")
      .then((res) => {
        if (!res.ok) {
          throw new Error(`API error: ${res.status}`);
        }
        return res.json() as Promise<HelloResponse>;
      })
      .then(setData)
      .catch((err: unknown) => {
        const message = err instanceof Error ? err.message : "Unknown error";
        setError(message);
      });
  }, []);

  return (
    <main className="page">
      <header className="hero">
        <p className="eyebrow">learnhub-core</p>
        <h1>学習管理システム</h1>
        <p className="lead">Cloud Run デプロイ用スケルトン</p>
      </header>

      <section className="card">
        <h2>API 接続確認</h2>
        {error && <p className="status error">{error}</p>}
        {!error && !data && <p className="status">読み込み中...</p>}
        {data && (
          <dl className="meta">
            <div>
              <dt>message</dt>
              <dd>{data.message}</dd>
            </div>
            <div>
              <dt>environment</dt>
              <dd>{data.environment}</dd>
            </div>
          </dl>
        )}
      </section>
    </main>
  );
}
