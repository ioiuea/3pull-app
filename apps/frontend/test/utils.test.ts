import { describe, expect, it } from "vitest"

import { cn } from "@/lib/utils"

// このファイルは `cn` ヘルパーの基本契約を固定します。
// `cn` は多くの UI コンポーネントで使われるため、
// 1 ケースでも期待動作を明示しておくと回帰の影響範囲を早く特定できます。
describe("cn", () => {
  it("merges class names and resolves tailwind conflicts", () => {
    // このテストは `cn` の最重要責務を確認します:
    // 1) 複数のクラス文字列を 1 つに結合できること
    // 2) Tailwind の競合クラスがある場合に「後勝ち」で解決されること
    //
    // 例:
    // - `px-2` と `px-4` は同じ padding-x 系のため競合します。
    // - 呼び出し順の後ろにある `px-4` が最終結果として残る想定です。
    // - `text-sm` は競合しないため、そのまま保持されます。
    const result = cn("px-2", "text-sm", "px-4")

    // 期待する最終文字列:
    // - `px-2` は消える
    // - `text-sm` は残る
    // - `px-4` が採用される
    //
    // ここが崩れると、画面上のスタイルが意図せず上書きされなかったり
    // 重複クラスが残ってデバッグしづらくなるため、回帰防止として固定します。
    expect(result).toBe("text-sm px-4")
  })
})
