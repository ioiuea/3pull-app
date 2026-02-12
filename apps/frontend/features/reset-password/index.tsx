"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";

import { z } from "zod";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { authClient } from "@/lib/auth/client";

type Dictionary = typeof import("@/dictionaries/en.json");

type ResetPasswordClientProps = {
  dict: Dictionary;
};

const formSchema = z.object({
  password: z.string().min(8),
  confirmPassword: z.string().min(8),
});

export const ResetPasswordClient = ({ dict }: ResetPasswordClientProps) => {
  const { resetPassword } = dict;
  const searchParams = useSearchParams();
  const router = useRouter();

  const token = searchParams.get("token") as string;

  const [isLoading, setIsLoading] = useState(false);

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      password: "",
      confirmPassword: "",
    },
  });

  async function onSubmit(values: z.infer<typeof formSchema>) {
    setIsLoading(true);

    if (values.password !== values.confirmPassword) {
      toast.error("Passwords do not match");
      setIsLoading(false);
      return;
    }

    const { error } = await authClient.resetPassword({
      newPassword: values.password,
      token,
    });

    if (error) {
      toast.error(error.message);
    } else {
      toast.success("Password reset successfully");
      router.push("/login");
    }

    setIsLoading(false);
  }

  return (
    <div className="flex flex-col gap-6">
      <Card>
        <CardHeader className="text-center">
          <CardTitle className="text-xl">{resetPassword.title}</CardTitle>
          <CardDescription>{resetPassword.description}</CardDescription>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form className="space-y-8" onSubmit={form.handleSubmit(onSubmit)}>
              <div className="grid gap-6">
                <div className="grid gap-3">
                  <FormField
                    control={form.control}
                    name="password"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>{resetPassword.passwordLabel}</FormLabel>
                        <FormControl>
                          <Input {...field} type="password" />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
                <div className="grid gap-3">
                  <FormField
                    control={form.control}
                    name="confirmPassword"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>{resetPassword.confirmPasswordLabel}</FormLabel>
                        <FormControl>
                          <Input {...field} type="password" />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </div>
                <Button className="w-full" disabled={isLoading} type="submit">
                  {isLoading ? (
                    <Loader2 className="size-4 animate-spin" />
                  ) : (
                    resetPassword.submitCta
                  )}
                </Button>
              </div>
              <div className="text-center text-sm">
                {resetPassword.noAccount}{" "}
                <Link className="underline underline-offset-4" href="/signup">
                  {resetPassword.signupLink}
                </Link>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
      <div className="text-balance text-center text-muted-foreground text-xs *:[a]:underline *:[a]:underline-offset-4 *:[a]:hover:text-primary">
        {resetPassword.agreePrefix}
        <Link href="/terms">{resetPassword.termsOfService}</Link>
        {resetPassword.agreeLinkSeparator}
        <Link href="/privacy">{resetPassword.privacyPolicy}</Link>
        {resetPassword.agreeSuffix}
      </div>
    </div>
  );
};
