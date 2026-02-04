// Used by `apps/web/proxy.ts` to determine which routes bypass auth checks in Edge middleware.
export const PUBLIC_PATHS = [
  "/",
  "/login",
  "/terms",
  "/privacy",
  "/signup",
  "/forgot-password",
];
