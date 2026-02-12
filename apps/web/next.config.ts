import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    // NOTE: `/backend/*` をAPIサーバへプロキシして同一オリジンに見せる。
    // CORSを回避しつつ、Next.jsの `/api/*` ルートは影響を受けない。
    // APIの認証・認可など保護機能はFastAPI側で実装する前提。
    const apiBaseUrl =
      process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

    return [
      {
        // 例: /backend/v1/healthz -> http://localhost:8000/backend/v1/healthz
        source: "/backend/:path*",
        destination: `${apiBaseUrl}/backend/:path*`,
      },
    ];
  },
};

export default nextConfig;
