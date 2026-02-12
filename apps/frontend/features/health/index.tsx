"use client";

import Link from "next/link";
import { useCallback, useMemo, useState } from "react";
import { motion } from "motion/react";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { API_VERSION } from "@/const/app";
import { type Locale } from "@/lib/i18n";

type Dictionary = typeof import("@/dictionaries/en.json");

type HealthClientProps = {
  dict: Dictionary;
  lang: Locale;
};

type HealthStatus = "idle" | "loading" | "ok" | "error";

type HealthState = {
  status: HealthStatus;
  message?: string;
  checkedAt?: string;
  payload?: {
    app?: string;
    now?: string;
    version?: string;
  };
};

export const HealthClient = ({ dict, lang }: HealthClientProps) => {
  const { health } = dict;
  const [state, setState] = useState<HealthState>({ status: "idle" });

  const endpoint = `/backend/${API_VERSION}/healthz`;

  const checkHealth = useCallback(async () => {
    setState({ status: "loading" });
    try {
      const response = await fetch(endpoint, { cache: "no-store" });
      if (!response.ok) {
        throw new Error(`${health.errorPrefix} ${response.status}`);
      }
      const data = (await response.json()) as {
        status?: string;
        app?: string;
        now?: string;
        version?: string;
      };
      setState({
        status: "ok",
        message: data.status ?? health.okMessageFallback,
        checkedAt: new Date().toISOString(),
        payload: {
          app: data.app,
          now: data.now,
          version: data.version,
        },
      });
    } catch (error) {
      setState({
        status: "error",
        message:
          error instanceof Error ? error.message : health.errorFallbackMessage,
        checkedAt: new Date().toISOString(),
      });
    }
  }, [endpoint, health]);

  const statusLabel = useMemo(() => {
    if (state.status === "loading") return health.loadingLabel;
    if (state.status === "ok") return health.okLabel;
    if (state.status === "error") return health.errorLabel;
    return health.idleLabel;
  }, [health, state.status]);

  const statusVariant = useMemo(() => {
    if (state.status === "ok") return "secondary" as const;
    if (state.status === "error") return "destructive" as const;
    return "outline" as const;
  }, [state.status]);

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
            <Link href={`/${lang}`}>{health.backToHome}</Link>
          </Button>
        </div>

        <Card className="border-0 bg-transparent shadow-none">
          <CardHeader className="px-0 pb-4">
            <div className="flex items-center gap-3">
              <Badge variant="secondary">{health.badge}</Badge>
              <Badge variant={statusVariant}>{statusLabel}</Badge>
            </div>
            <CardTitle className="text-4xl font-semibold tracking-tight">
              {health.title}
            </CardTitle>
            <CardDescription className="text-base leading-7">
              {health.description}
            </CardDescription>
          </CardHeader>
          <Separator />
        </Card>

        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
        >
          <Card>
            <CardHeader>
              <CardTitle>{health.cardTitle}</CardTitle>
              <CardDescription>{health.cardDescription}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="rounded-lg border border-dashed border-muted-foreground/40 bg-background/70 p-4 text-sm">
                <p className="font-semibold text-muted-foreground">
                  {health.endpointLabel}
                </p>
                <p className="mt-2 break-all font-mono text-foreground">
                  {endpoint}
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-3">
                <Button onClick={checkHealth} disabled={state.status === "loading"}>
                  {health.checkButton}
                </Button>
                {state.checkedAt && (
                  <span className="text-xs text-muted-foreground">
                    {health.lastCheckedLabel}: {" "}
                    {new Date(state.checkedAt).toLocaleTimeString(lang)}
                  </span>
                )}
              </div>

              {state.status === "ok" && (
                <Alert>
                  <AlertTitle>{health.successTitle}</AlertTitle>
                  <AlertDescription>
                    <div>
                      {health.responseLabel}: {state.message}
                    </div>
                    <div>
                      {health.appLabel}: {state.payload?.app ?? "-"}
                    </div>
                    <div>
                      {health.versionLabel}: {state.payload?.version ?? "-"}
                    </div>
                    <div>
                      {health.nowLabel}:{" "}
                      {state.payload?.now
                        ? new Date(state.payload.now).toLocaleString(lang)
                        : "-"}
                    </div>
                  </AlertDescription>
                </Alert>
              )}

              {state.status === "error" && (
                <Alert variant="destructive">
                  <AlertTitle>{health.errorTitle}</AlertTitle>
                  <AlertDescription>{state.message}</AlertDescription>
                </Alert>
              )}
            </CardContent>
          </Card>
        </motion.section>
      </motion.div>
    </div>
  );
};
