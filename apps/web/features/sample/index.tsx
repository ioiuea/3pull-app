"use client";

import { useMemo, useState } from "react";
import useSWR from "swr";
import { z } from "zod";
import { motion } from "motion/react";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import {
  Item,
  ItemContent,
  ItemDescription,
  ItemGroup,
  ItemSeparator,
  ItemTitle,
} from "@/components/ui/item";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import useSampleStore from "@/store/sampleStore";

const TipSchema = z.object({
  id: z.string(),
  title: z.string(),
  detail: z.string(),
});

const TipsResponseSchema = z.object({
  query: z.string(),
  items: z.array(TipSchema),
  generatedAt: z.string(),
});

const FormSchema = z.object({
  name: z.string().min(2, "名前は2文字以上で入力してください。"),
  age: z.coerce
    .number()
    .int("年齢は整数で入力してください。")
    .min(13, "年齢は13以上で入力してください。")
    .max(120, "年齢は120以下で入力してください。"),
});

const fetcher = async (url: string) => {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error("データの取得に失敗しました。");
  }
  const data = await response.json();
  return TipsResponseSchema.parse(data);
};

const SampleClient = () => {
  const { count, label, setLabel, increment, decrement, reset } =
    useSampleStore();
  const [query, setQuery] = useState("");
  const [formValues, setFormValues] = useState({ name: "", age: "" });
  const [formResult, setFormResult] = useState<{
    ok: boolean;
    message: string;
  } | null>(null);

  const { data, error, isLoading } = useSWR(
    `/api/sample?q=${encodeURIComponent(query)}`,
    fetcher,
  );

  const formErrors = useMemo(() => {
    if (!formResult || formResult.ok) {
      return [];
    }
    return formResult.message.split("\n");
  }, [formResult]);

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const parsed = FormSchema.safeParse({
      name: formValues.name,
      age: formValues.age,
    });

    if (!parsed.success) {
      const messages = parsed.error.issues.map((issue) => issue.message);
      setFormResult({ ok: false, message: messages.join("\n") });
      return;
    }

    setFormResult({
      ok: true,
      message: `${parsed.data.name} さん（${parsed.data.age}歳）で登録しました。`,
    });
  };

  return (
    <div className="min-h-screen bg-linear-to-br from-background via-muted/40 to-muted/70 px-6 py-12 text-foreground">
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="mx-auto flex w-full max-w-5xl flex-col gap-8"
      >
        <Card className="border-0 bg-transparent shadow-none">
          <CardHeader className="px-0 pb-4">
            <div className="flex items-center gap-3">
              <Badge variant="secondary">Sample Playground</Badge>
              <Badge variant="outline">Zustand</Badge>
              <Badge variant="outline">Zod</Badge>
              <Badge variant="outline">SWR</Badge>
            </div>
            <CardTitle className="text-4xl font-semibold tracking-tight">
              Zustand / Zod / SWR をまとめて体験
            </CardTitle>
            <CardDescription className="text-base leading-7">
              3つのライブラリを小さな体験にまとめたサンプルです。左は
              Zustand のストア、中央は Zod バリデーション、右は SWR の取得結果です。
            </CardDescription>
          </CardHeader>
          <Separator />
        </Card>

        <motion.section
          initial="hidden"
          animate="show"
          variants={{
            hidden: { opacity: 0 },
            show: {
              opacity: 1,
              transition: { staggerChildren: 0.12 },
            },
          }}
          className="grid gap-6 lg:grid-cols-3"
        >
          <motion.div
            variants={{
              hidden: { opacity: 0, y: 16 },
              show: { opacity: 1, y: 0 },
            }}
          >
            <Card>
              <CardHeader className="flex flex-row items-start justify-between gap-4">
                <div>
                  <CardTitle>Zustand ストア</CardTitle>
                  <CardDescription>
                    共有状態をすばやく同期します。
                  </CardDescription>
                </div>
                <Badge>{label}</Badge>
              </CardHeader>
              <CardContent className="space-y-4">
                <motion.p
                  key={count}
                  initial={{ scale: 0.9, opacity: 0.6 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ duration: 0.25 }}
                  className="text-4xl font-semibold"
                >
                  {count}
                </motion.p>
                <div className="flex flex-wrap gap-2">
                  <Button type="button" onClick={increment}>
                    +1
                  </Button>
                  <Button type="button" variant="secondary" onClick={decrement}>
                    -1
                  </Button>
                  <Button type="button" variant="outline" onClick={reset}>
                    Reset
                  </Button>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="label-input">ラベル変更</Label>
                  <Input
                    id="label-input"
                    value={label}
                    onChange={(event) => setLabel(event.target.value)}
                  />
                </div>
              </CardContent>
            </Card>
          </motion.div>

          <motion.div
            variants={{
              hidden: { opacity: 0, y: 16 },
              show: { opacity: 1, y: 0 },
            }}
          >
            <Card>
              <CardHeader>
                <CardTitle>Zod フォーム</CardTitle>
                <CardDescription>
                  入力を Zod で検証して、その場で結果を表示します。
                </CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="name-input">名前</Label>
                    <Input
                      id="name-input"
                      value={formValues.name}
                      onChange={(event) =>
                        setFormValues((prev) => ({
                          ...prev,
                          name: event.target.value,
                        }))
                      }
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="age-input">年齢</Label>
                    <Input
                      id="age-input"
                      value={formValues.age}
                      onChange={(event) =>
                        setFormValues((prev) => ({
                          ...prev,
                          age: event.target.value,
                        }))
                      }
                    />
                  </div>
                  <Button type="submit" className="w-full">
                    検証して保存
                  </Button>
                </form>
              </CardContent>
              {formResult && (
                <CardFooter className="flex-col items-start gap-2">
                  <Alert
                    variant={formResult.ok ? "default" : "destructive"}
                    className={
                      formResult.ok
                        ? "border-emerald-200 bg-emerald-50 text-emerald-700 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-200"
                        : ""
                    }
                  >
                    <AlertTitle>
                      {formResult.ok ? "登録完了" : "入力エラー"}
                    </AlertTitle>
                    <AlertDescription>
                      {formResult.ok ? (
                        <p>{formResult.message}</p>
                      ) : (
                        <ul className="list-disc space-y-1 pl-4">
                          {formErrors.map((message) => (
                            <li key={message}>{message}</li>
                          ))}
                        </ul>
                      )}
                    </AlertDescription>
                  </Alert>
                </CardFooter>
              )}
            </Card>
          </motion.div>

          <motion.div
            variants={{
              hidden: { opacity: 0, y: 16 },
              show: { opacity: 1, y: 0 },
            }}
          >
            <Card>
              <CardHeader className="flex flex-row items-start justify-between gap-4">
                <div>
                  <CardTitle>SWR データ</CardTitle>
                  <CardDescription>
                    API から取得したデータをリアクティブに更新します。
                  </CardDescription>
                </div>
                <Badge variant="secondary">
                  {data ? `${data.items.length} items` : "loading"}
                </Badge>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="search-input">検索</Label>
                  <Input
                    id="search-input"
                    value={query}
                    onChange={(event) => setQuery(event.target.value)}
                    placeholder="zustand など"
                  />
                </div>
                {isLoading && (
                  <div className="space-y-2">
                    <Skeleton className="h-12 w-full" />
                    <Skeleton className="h-12 w-full" />
                    <Skeleton className="h-12 w-full" />
                  </div>
                )}
                {error && (
                  <Alert variant="destructive">
                    <AlertTitle>取得エラー</AlertTitle>
                    <AlertDescription>
                      データ取得に失敗しました。再試行してください。
                    </AlertDescription>
                  </Alert>
                )}
                {data && (
                  <ItemGroup>
                    {data.items.map((item, index) => (
                      <div key={item.id}>
                        <Item variant="outline">
                          <ItemContent>
                            <ItemTitle>{item.title}</ItemTitle>
                            <ItemDescription>{item.detail}</ItemDescription>
                          </ItemContent>
                        </Item>
                        {index < data.items.length - 1 && <ItemSeparator />}
                      </div>
                    ))}
                  </ItemGroup>
                )}
                {data && data.items.length === 0 && (
                  <Alert>
                    <AlertTitle>結果なし</AlertTitle>
                    <AlertDescription>
                      条件に一致するデータがありません。
                    </AlertDescription>
                  </Alert>
                )}
                {data && (
                  <p className="text-xs text-muted-foreground">
                    updated: {new Date(data.generatedAt).toLocaleTimeString()}
                  </p>
                )}
              </CardContent>
            </Card>
          </motion.div>
        </motion.section>
      </motion.div>
    </div>
  );
};

export default SampleClient;
