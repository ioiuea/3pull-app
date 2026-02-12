import { describe, expect, it } from "vitest"

import { DEFAULT_LOCALE, SUPPORTED_LOCALES, getDictionary, getLang } from "@/lib/i18n"

// このファイルは i18n の「壊れると画面全体に影響する基礎挙動」を固定するためのテストです。
// 文言そのものの品質ではなく、言語選択と辞書解決のルールを守れているかに焦点を当てます。
describe("i18n locales", () => {
  it("defines supported locales and default locale consistently", () => {
    // このテストは「対応言語の一覧」と「デフォルト言語」の整合性を守るためのものです。
    // 例えば default が対応外の値になってしまう事故を防ぎます。
    // `toEqual` で配列全体を固定することで、想定外の言語追加/削除も検知します。
    expect(SUPPORTED_LOCALES).toEqual(["en", "ja"])

    // default は必ず対応言語のどれかでなければいけません。
    expect(SUPPORTED_LOCALES).toContain(DEFAULT_LOCALE)

    // 現在の仕様として en が既定値であることを明示的に固定します。
    expect(DEFAULT_LOCALE).toBe("en")
  })
})

describe("getLang", () => {
  it("returns locale cookie value when it is supported", async () => {
    // 正常系: ユーザーが有効な言語を指定した場合は、その値をそのまま使うことを確認します。
    // ここで変換せず返すことで、利用側は「有効値はそのまま来る」と前提を置けます。
    await expect(getLang("ja")).resolves.toBe("ja")
    await expect(getLang("en")).resolves.toBe("en")
  })

  it("falls back to default locale when cookie is unsupported or missing", async () => {
    // 異常系: 未対応の文字列や undefined が来た時に、安全にデフォルトへ戻ることを確認します。
    // これにより不正な cookie 値でも画面表示が壊れません。
    // `fr` は未対応値の具体例、`undefined` は cookie 不在ケースです。
    await expect(getLang("fr")).resolves.toBe(DEFAULT_LOCALE)
    await expect(getLang(undefined)).resolves.toBe(DEFAULT_LOCALE)
  })
})

describe("getDictionary", () => {
  it("loads dictionary json that matches the locale", async () => {
    // このテストは「ロケールごとに正しい辞書ファイルを読み込めるか」を保証します。
    // 文言の中身を固定値で持つのではなく、実ファイルと一致するかで検証して保守性を上げます。
    // そのため、期待値はハードコードせず実際の JSON を import して比較します。
    const enDictionary = (await import("@/dictionaries/en.json")).default
    const jaDictionary = (await import("@/dictionaries/ja.json")).default

    // getDictionary(locale) が locale 対応の辞書を返していることを locale ごとに確認します。
    await expect(getDictionary("en")).resolves.toEqual(enDictionary)
    await expect(getDictionary("ja")).resolves.toEqual(jaDictionary)
  })
})
