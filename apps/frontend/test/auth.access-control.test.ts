import { describe, expect, it } from "vitest"

import { admin, member, owner, statement } from "@/lib/auth/access-control"

// このファイルは「権限定義ファイルが最低限の契約を満たしているか」を確認します。
// 権限ライブラリ内部の詳細動作までテストするのではなく、
// このプロジェクトが依存している公開値の破壊的変更を検知する目的です。
describe("auth/access-control", () => {
  it("defines project permissions in statement", () => {
    // 権限定義の土台となる statement が崩れていないか確認します。
    // ここが崩れるとロール側の許可判定も連鎖的に壊れます。
    // 配列の内容と順序を固定して、意図しない差分を早期に拾います。
    expect(statement.project).toEqual(["create", "share", "update", "delete"])
  })

  it("exports all organization roles used by auth settings", () => {
    // auth/server.ts から参照しているロールが未定義になっていないことを確認します。
    // 実行時の初期化エラーを早期に検知する目的です。
    // ここでは権限内容の正しさではなく「参照可能であること」を保証します。
    expect(member).toBeDefined()
    expect(admin).toBeDefined()
    expect(owner).toBeDefined()
  })
})
