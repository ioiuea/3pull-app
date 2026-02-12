import { NextResponse } from "next/server";
import { z } from "zod";

const QuerySchema = z.object({
  q: z.string().trim().max(30).optional().default(""),
});

const ItemSchema = z.object({
  id: z.string(),
  title: z.string(),
  detail: z.string(),
});

const ResponseSchema = z.object({
  query: z.string(),
  items: z.array(ItemSchema),
  generatedAt: z.string(),
});

const ITEMS = [
  {
    id: "state",
    title: "Zustand state",
    detail: "A tiny store can power shared UI state without prop drilling.",
  },
  {
    id: "schema",
    title: "Zod schemas",
    detail: "Runtime validation keeps client/server data in sync.",
  },
  {
    id: "fetch",
    title: "SWR data fetching",
    detail: "Built-in caching keeps the UI responsive.",
  },
  {
    id: "ui",
    title: "Composable UI",
    detail: "Mix stores, schemas, and fetchers for fast iteration.",
  },
];

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const parsedQuery = QuerySchema.parse({ q: searchParams.get("q") ?? "" });
  const queryLower = parsedQuery.q.toLowerCase();

  const items =
    queryLower.length === 0
      ? ITEMS
      : ITEMS.filter(
          (item) =>
            item.title.toLowerCase().includes(queryLower) ||
            item.detail.toLowerCase().includes(queryLower),
        );

  const payload = ResponseSchema.parse({
    query: parsedQuery.q,
    items,
    generatedAt: new Date().toISOString(),
  });

  return NextResponse.json(payload, {
    headers: {
      "Cache-Control": "no-store",
    },
  });
}
