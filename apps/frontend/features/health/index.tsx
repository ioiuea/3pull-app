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
import {
  fetchWithApiAuthRaw,
  getApiTokenMetadata,
  type ApiTokenMetadata,
} from "@/lib/auth/api-fetch";
import { authClient } from "@/lib/auth/client";
import { type Locale } from "@/lib/i18n/locales";

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
    dependencies?: Array<{
      name?: string;
      target?: string;
      status?: "ok" | "fail" | "skipped";
      latency_ms?: number | null;
      error?: string | null;
    }>;
  };
};

export const HealthClient = ({ dict, lang }: HealthClientProps) => {
  const { health } = dict;
  const [state, setState] = useState<HealthState>({ status: "idle" });
  const [tokenMetadata, setTokenMetadata] = useState<ApiTokenMetadata | null>(
    null,
  );
  const [profile, setProfile] = useState<{
    id?: string;
    name?: string;
    email?: string;
    emailVerified?: boolean;
    authMethod?: string;
    idpManaged?: boolean;
  } | null>(null);
  const [profileError, setProfileError] = useState<string | null>(null);
  const [isLoadingProfile, setIsLoadingProfile] = useState(false);

  const endpoint = `/backend/${API_VERSION}/healthz`;

  const checkHealth = useCallback(async () => {
    setState({ status: "loading" });
    try {
      const metadata = await getApiTokenMetadata();
      setTokenMetadata(metadata);

      const response = await fetchWithApiAuthRaw(endpoint, {
        cache: "no-store",
      });
      if (!response) {
        throw new Error(`${health.errorPrefix} 401`);
      }
      if (!response.ok) {
        throw new Error(`${health.errorPrefix} ${response.status}`);
      }
      const data = (await response.json()) as {
        status?: string;
        app?: string;
        now?: string;
        version?: string;
        dependencies?: Array<{
          name?: string;
          target?: string;
          status?: "ok" | "fail" | "skipped";
          latency_ms?: number | null;
          error?: string | null;
        }>;
      };
      setState({
        status: data.status === "fail" ? "error" : "ok",
        message: data.status ?? health.okMessageFallback,
        checkedAt: new Date().toISOString(),
        payload: {
          app: data.app,
          now: data.now,
          version: data.version,
          dependencies: data.dependencies,
        }
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

  const loadProfile = useCallback(async () => {
    setIsLoadingProfile(true);
    setProfileError(null);
    try {
      const [sessionResult, lastLoginMethod] = await Promise.all([
        authClient.getSession(),
        Promise.resolve(authClient.getLastUsedLoginMethod()),
      ]);
      if (sessionResult.error) {
        throw new Error(sessionResult.error.message ?? health.profileErrorFallback);
      }
      const user = sessionResult.data?.user;
      if (!user) {
        throw new Error(health.profileNotAuthenticated);
      }
      const normalizedMethod = (lastLoginMethod ?? "unknown").toLowerCase();
      const idpManaged = normalizedMethod !== "email" && normalizedMethod !== "unknown";
      setProfile({
        id: user.id,
        name: user.name,
        email: user.email,
        emailVerified: Boolean(user.emailVerified),
        authMethod: lastLoginMethod ?? "unknown",
        idpManaged,
      });
    } catch (error) {
      setProfile(null);
      setProfileError(
        error instanceof Error ? error.message : health.profileErrorFallback,
      );
    } finally {
      setIsLoadingProfile(false);
    }
  }, [health.profileErrorFallback, health.profileNotAuthenticated]);

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
                <Button onClick={loadProfile} disabled={isLoadingProfile} variant="secondary">
                  {isLoadingProfile ? health.profileLoadingLabel : health.profileButton}
                </Button>
                {state.checkedAt && (
                  <span className="text-xs text-muted-foreground">
                    {health.lastCheckedLabel}: {" "}
                    {new Date(state.checkedAt).toLocaleTimeString(lang)}
                  </span>
                )}
              </div>

              {state.payload && (
                <Alert variant={state.status === "error" ? "destructive" : "default"}>
                  <AlertTitle>
                    {state.status === "error" ? health.errorTitle : health.successTitle}
                  </AlertTitle>
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
                    <div className="mt-3 space-y-1">
                      <p className="font-semibold">{health.tokenTitle}</p>
                      <div>
                        {health.tokenIssuerLabel}: {tokenMetadata?.issuer ?? "-"}
                      </div>
                      <div>
                        {health.tokenAudienceLabel}: {tokenMetadata?.audience ?? "-"}
                      </div>
                      <div>
                        {health.tokenExpiresAtLabel}:{" "}
                        {tokenMetadata?.expiresAt
                          ? new Date(tokenMetadata.expiresAt * 1000).toLocaleString(lang)
                          : "-"}
                      </div>
                    </div>
                    <div className="mt-3 space-y-2">
                      <p className="font-semibold">
                        {health.dependenciesTitle}
                      </p>
                      {(state.payload?.dependencies?.length ?? 0) === 0 && (
                        <p className="text-muted-foreground">
                          {health.dependenciesEmptyLabel}
                        </p>
                      )}
                      {state.payload?.dependencies?.map((dependency, index) => {
                        const depStatus = dependency.status ?? "skipped";
                        const depVariant =
                          depStatus === "ok"
                            ? ("secondary" as const)
                            : depStatus === "fail"
                              ? ("destructive" as const)
                              : ("outline" as const);

                        return (
                          <div
                            key={`${dependency.name ?? "dependency"}-${index}`}
                            className="rounded-md border p-3"
                          >
                            <div className="mb-2 flex items-center justify-between gap-2">
                              <span className="font-medium">
                                {dependency.name ?? "-"}
                              </span>
                              <Badge variant={depVariant}>{depStatus}</Badge>
                            </div>
                            <div className="text-sm text-muted-foreground">
                              {health.dependencyTargetLabel}:{" "}
                              {dependency.target ?? "-"}
                            </div>
                            <div className="text-sm text-muted-foreground">
                              {health.dependencyLatencyLabel}:{" "}
                              {dependency.latency_ms ?? "-"}
                            </div>
                            <div className="text-sm text-muted-foreground">
                              {health.dependencyErrorLabel}:{" "}
                              {dependency.error ?? "-"}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </AlertDescription>
                </Alert>
              )}

              {(profile || profileError) && (
                <Alert variant={profileError ? "destructive" : "default"}>
                  <AlertTitle>
                    {profileError ? health.profileErrorTitle : health.profileSuccessTitle}
                  </AlertTitle>
                  <AlertDescription>
                    {profileError && <div>{profileError}</div>}
                    {profile && (
                      <div className="space-y-1">
                        <div>
                          {health.profileIdLabel}: {profile.id ?? "-"}
                        </div>
                        <div>
                          {health.profileNameLabel}: {profile.name ?? "-"}
                        </div>
                        <div>
                          {health.profileEmailLabel}: {profile.email ?? "-"}
                        </div>
                        <div>
                          {health.profileEmailVerifiedLabel}:{" "}
                          {profile.emailVerified ? health.profileYesLabel : health.profileNoLabel}
                        </div>
                        <div>
                          {health.profileAuthMethodLabel}: {profile.authMethod ?? "-"}
                        </div>
                        <div>
                          {health.profileIdpManagedLabel}:{" "}
                          {profile.idpManaged ? health.profileYesLabel : health.profileNoLabel}
                        </div>
                      </div>
                    )}
                  </AlertDescription>
                </Alert>
              )}

              {state.status === "error" && !state.payload && (
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
