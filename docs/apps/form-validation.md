# フロントエンド Zod フォームバリデーションガイド

このドキュメントは、`apps/frontend` での Zod を使ったフォームバリデーション実装の基本パターンをまとめたものです。

## 概要

- 本リポジトリのフォーム実装は `react-hook-form` と `@hookform/resolvers/zod` を組み合わせる構成が基本です。
- UI は `components/ui/form`（shadcn/ui）を使い、エラーメッセージは `FormMessage` で表示します。
- Zod スキーマは「利用箇所の近く」に置き、再利用が必要なものだけ `utils/` に切り出します。

## 主要ファイルと責務

- `apps/frontend/features/login/index.tsx`
  - `z.object(...)` + `zodResolver(...)` の基本形。
- `apps/frontend/features/signup/index.tsx`
  - 複数フィールド（`username/email/password`）の検証例。
- `apps/frontend/features/forgot-password/index.tsx`
  - 単一フィールド（メール）検証の最小構成。
- `apps/frontend/components/ui/form.tsx`
  - `Form`, `FormField`, `FormMessage` などのフォーム UI 基盤。

## 実装手順（推奨パターン）

1. クライアントコンポーネントでスキーマを定義する。
2. `useForm<z.infer<typeof schema>>` で型を推論する。
3. `resolver: zodResolver(schema)` を設定する。
4. `FormField` + `FormMessage` でエラーを描画する。
5. `onSubmit` は `form.handleSubmit(onSubmit)` 経由で受ける。

```tsx
"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";

const formSchema = z.object({
  email: z.email(),
  password: z.string().min(8, "8文字以上で入力してください"),
});

type FormValues = z.infer<typeof formSchema>;

export const ExampleClient = () => {
  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: { email: "", password: "" },
  });

  const onSubmit = async (values: FormValues) => {
    // API 呼び出しなど
    console.log(values);
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="password"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Password</FormLabel>
              <FormControl>
                <Input type="password" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit">Submit</Button>
      </form>
    </Form>
  );
};
```

## 複数フィールドの相関チェック（確認用パスワードなど）

`reset-password` のような「項目間チェック」は、`onSubmit` での分岐ではなく、可能な限り Zod 側で定義します。`superRefine` を使うと `FormMessage` と統一した表示ができます。

```tsx
const formSchema = z
  .object({
    password: z.string().min(8, "8文字以上で入力してください"),
    confirmPassword: z.string().min(8, "8文字以上で入力してください"),
  })
  .superRefine((values, ctx) => {
    if (values.password !== values.confirmPassword) {
      ctx.addIssue({
        code: "custom",
        path: ["confirmPassword"],
        message: "パスワードが一致しません",
      });
    }
  });
```

## i18n とバリデーション文言

- 画面文言と同様に、バリデーションメッセージも辞書（`dictionaries/*.json`）から受け取る運用を推奨します。
- `app/[lang]/.../page.tsx` で辞書を取得し、`features/.../index.tsx` に `dict` として渡してください（詳細: `docs/apps/i18n.md`）。

## 運用ルール

- ページ専用のスキーマは該当 `features/<page>/index.tsx` 近傍に配置。
- 複数画面で再利用するスキーマだけ `apps/frontend/utils/` へ切り出し。
- `safeParse` を使う独立検証（例: API レスポンス検証）はフォーム検証と分離して扱う。
- エラー表示は `FormMessage` を基本にし、`toast` は送信結果（成功/失敗通知）に寄せる。

## 関連ドキュメント

- `docs/apps/i18n.md`
- `docs/apps/auth.md`
