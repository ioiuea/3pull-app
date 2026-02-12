// Next.js の `server-only` はランタイム制約用マーカー。
// Vitest では実体が不要なため、空モジュールとして扱います。
// これにより `import "server-only"` を含むモジュールも Node テスト環境で読み込めます。
export {}
