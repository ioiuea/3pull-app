"use client";

import Link from "next/link";
import { useState } from "react";
import useSWR from "swr";
import { z } from "zod";
import { motion } from "motion/react";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
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
import { Skeleton } from "@/components/ui/skeleton";
import { type Locale } from "@/lib/i18n";

type Dictionary = typeof import("@/dictionaries/en.json");

type SampleSwrClientProps = {
  dict: Dictionary;
  lang: Locale;
};

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

export const SampleSwrClient = ({ dict, lang }: SampleSwrClientProps) => {
  const { sample } = dict;
  const [query, setQuery] = useState("");

  const fetcher = async (url: string) => {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(sample.swr.fetchErrorMessage);
    }
    const data = await response.json();
    return TipsResponseSchema.parse(data);
  };

  const { data, error, isLoading } = useSWR(
    `/api/sample?q=${encodeURIComponent(query)}`,
    fetcher,
  );

  const badgeText = data
    ? sample.swr.itemsBadge.replace("{count}", String(data.items.length))
    : sample.swr.loadingBadge;

  return (
    <div className="min-h-screen bg-linear-to-br from-background via-muted/40 to-muted/70 px-6 py-12 text-foreground">
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="mx-auto flex w-full max-w-4xl flex-col gap-8"
      >
        <div>
          <Button asChild variant="ghost">
            <Link href={`/${lang}/sample`}>{sample.backToSamples}</Link>
          </Button>
        </div>

        <Card className="border-0 bg-transparent shadow-none">
          <CardHeader className="px-0 pb-4">
            <div className="flex items-center gap-3">
              <Badge variant="secondary">{sample.index.badge}</Badge>
              <Badge variant="outline">{sample.swr.badge}</Badge>
            </div>
            <CardTitle className="text-4xl font-semibold tracking-tight">
              {sample.swr.title}
            </CardTitle>
            <p className="text-base leading-7 text-muted-foreground">
              {sample.swr.description}
            </p>
          </CardHeader>
        </Card>

        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
        >
          <Card>
            <CardHeader className="flex flex-row items-start justify-between gap-4">
              <div>
                <CardTitle>{sample.swr.dataTitle}</CardTitle>
                <p className="text-sm text-muted-foreground">
                  {sample.swr.dataDescription}
                </p>
              </div>
              <Badge variant="secondary">{badgeText}</Badge>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="search-input">{sample.swr.searchLabel}</Label>
                <Input
                  id="search-input"
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  placeholder={sample.swr.searchPlaceholder}
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
                  <AlertTitle>{sample.swr.errorTitle}</AlertTitle>
                  <AlertDescription>
                    {sample.swr.errorDescription}
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
                  <AlertTitle>{sample.swr.emptyTitle}</AlertTitle>
                  <AlertDescription>{sample.swr.emptyDescription}</AlertDescription>
                </Alert>
              )}
              {data && (
                <p className="text-xs text-muted-foreground">
                  {sample.swr.updatedLabel}:{" "}
                  {new Date(data.generatedAt).toLocaleTimeString(lang)}
                </p>
              )}
            </CardContent>
          </Card>
        </motion.section>
      </motion.div>
    </div>
  );
};
