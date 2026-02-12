"use server";

import { eq, inArray, not } from "drizzle-orm";
import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { db } from "@/drizzle/drizzle";
import { member, user } from "@/drizzle/schema";
import { auth } from "@/lib/auth";

export const getCurrentUser = async () => {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session) {
    redirect("/login");
  }

  const currentUser = await db.query.user.findFirst({
    where: eq(user.id, session.user.id),
  });

  if (!currentUser) {
    redirect("/login");
  }

  return {
    ...session,
    currentUser,
  };
};

export const signIn = async (email: string, password: string) => {
  try {
    await auth.api.signInEmail({
      body: {
        email,
        password,
      },
    });

    return {
      success: true,
      message: "Signed in successfully.",
    };
  } catch (error) {
    console.error("[signIn] auth.api.signInEmail failed", error);
    const e = error as Error;

    return {
      success: false,
      message: e.message || "An unknown error occurred.",
    };
  }
};

export const signUp = async (
  email: string,
  password: string,
  username: string
) => {
  const startTime = Date.now();
  try {
    console.log("[signUp] invoked", { email });
    const timeoutMs = process.env.SIGNUP_DEBUG === "1" ? 5000 : 0;
    const signUpPromise = auth.api.signUpEmail({
      body: {
        email,
        password,
        name: username,
      },
    });
    const result =
      timeoutMs > 0
        ? await Promise.race([
            signUpPromise,
            new Promise<"__timeout__">((resolve) =>
              setTimeout(() => resolve("__timeout__"), timeoutMs)
            ),
          ])
        : await signUpPromise;

    if (result === "__timeout__") {
      console.error("[signUp] signUpEmail timeout", { timeoutMs });
      return {
        success: false,
        message: "Sign up timed out.",
      };
    }

    console.log("[signUp] signUpEmail returned", {
      type: typeof result,
      isResponse: result instanceof Response,
      durationMs: Date.now() - startTime,
    });

    if (result instanceof Response) {
      const bodyText = await result.clone().text();
      if (!result.ok) {
        console.error("[signUp] auth.api.signUpEmail response error", {
          status: result.status,
          statusText: result.statusText,
          body: bodyText,
        });
        return {
          success: false,
          message: `Sign up failed (status ${result.status}).`,
        };
      }
      console.info("[signUp] auth.api.signUpEmail response ok", {
        status: result.status,
        body: bodyText,
      });
      return {
        success: true,
        message: "Signed up successfully.",
      };
    }

    const resultAny = result as unknown as { user?: { id?: string } };
    if (!resultAny?.user?.id) {
      console.warn("[signUp] auth.api.signUpEmail returned no user", result);
      return {
        success: false,
        message: "Sign up failed (no user returned).",
      };
    }

    return {
      success: true,
      message: "Signed up successfully.",
    };
  } catch (error) {
    console.error("[signUp] auth.api.signUpEmail failed", error);
    const e = error as Error;
    const message = e.message || "An unknown error occurred.";
    const normalizedEmail = email.toLowerCase();

    if (message.includes("User already exists")) {
      const existingUser = await db.query.user.findFirst({
        where: eq(user.email, normalizedEmail),
      });

      if (existingUser && existingUser.emailVerified === false) {
        try {
          await auth.api.sendVerificationEmail({
            body: { email: normalizedEmail },
          });
          return {
            success: true,
            message:
              "User already exists. Verification email has been resent.",
          };
        } catch (resendError) {
          console.error("[signUp] resend verification failed", resendError);
          return {
            success: false,
            message:
              "User already exists, but failed to resend verification email.",
          };
        }
      }
    }

    return {
      success: false,
      message,
    };
  } finally {
    console.log("[signUp] finished", { durationMs: Date.now() - startTime });
  }
};

export const getUsers = async (organizationId: string) => {
  try {
    const members = await db.query.member.findMany({
      where: eq(member.organizationId, organizationId),
    });

    const users = await db.query.user.findMany({
      where: not(
        inArray(
          user.id,
          members.map((m) => m.userId)
        )
      ),
    });

    return users;
  } catch (error) {
    console.error(error);
    return [];
  }
};
