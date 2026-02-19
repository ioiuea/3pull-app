# PR 前セルフチェックガイド（CI運用）

このドキュメントは、PR を作成する前にローカルで実施するセルフチェック手順を定義します。  
GitHub Actions の CI（`.github/workflows/ci.yml`）と同等の確認を、事前に開発者が実行することを目的とします。

## 対象

- Frontend: format / lint / typecheck / test
- Backend: format / lint / typecheck / test
- 実行コマンドの正は `Makefile` の `frontend-ci` / `backend-ci` / `all-ci`

## 最短手順（推奨）

リポジトリルートで次を実行します。

```bash
make frontend-install
make backend-install
make all-ci
```

`make all-ci` が通ることを、PR 作成前の必須条件とします。

## 個別実行（問題切り分け用）

### Frontend

```bash
make frontend-format
make frontend-lint
make frontend-typecheck
make frontend-test
```

### Backend

```bash
make backend-format
make backend-lint
make backend-typecheck
make backend-test
```

## 自動修正コマンド

フォーマット/一部 lint は自動修正できます。修正後は必ず CI チェックを再実行してください。

```bash
make frontend-format-fix
make frontend-lint-fix
make backend-format-fix
make backend-lint-fix
make all-ci
```

## PR 前チェックリスト

1. 依存関係を最新 lockfile でインストールした。
2. `make all-ci` がローカルで成功した。
3. 生成物や不要ファイル（ログ・一時ファイル）をコミット対象に含めていない。
4. ドキュメント変更が必要な差分（仕様変更・運用変更）を反映した。
5. テスト追加が必要な変更に対して、テストを追加・更新した。

## 失敗時の対応方針

- format/lint 失敗:
  - まず `*-fix` を実行し、意図しない変更がないか確認して再実行する。
- typecheck 失敗:
  - `any` で回避せず、型定義・境界の入出力型を修正する。
- test 失敗:
  - flaky を疑う前に、前提データ・モック・時刻依存を確認する。
  - ローカル環境依存の差分を排除してから再実行する。

## CI との整合性

- CI は `.github/workflows/ci.yml` で `make all-ci` を実行します。
- ローカルも同じ `Makefile` ターゲットを使うことで、手元と CI の差異を最小化します。

## 関連ファイル

- `.github/workflows/ci.yml`
- `Makefile`
- `docs/apps/test-code.md`
