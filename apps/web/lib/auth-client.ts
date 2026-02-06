import {
  lastLoginMethodClient,
  organizationClient,
} from "better-auth/client/plugins";
import { createAuthClient } from "better-auth/react";
import { AUTH_BASE_URL } from "@/const/app";

export const authClient = createAuthClient({
  baseURL: AUTH_BASE_URL,
  plugins: [organizationClient(), lastLoginMethodClient()],
});
