"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";
import Link from "next/link";
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

const formSchema = z.object({
  email: z.email(),
});

type Dictionary = typeof import("@/dictionaries/en.json");

type ForgotPasswordClientProps = {
  dict: Dictionary;
};

export const ForgotPasswordClient = ({ dict }: ForgotPasswordClientProps) => {
  const { forgotPassword } = dict;
  const [isLoading, setIsLoading] = useState(false);

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      email: "",
    },
  });

  async function onSubmit(values: z.infer<typeof formSchema>) {
    setIsLoading(true);

    const { error } = await authClient.requestPasswordReset({
      email: values.email,
      redirectTo: "/reset-password",
    });

    if (error) {
      toast.error(error.message);
    } else {
      toast.success("Password reset email sent");
    }

    setIsLoading(false);
  }

  return (
    <div className="flex flex-col gap-6">
      <Card>
        <CardHeader className="text-center">
          <CardTitle className="text-xl">{forgotPassword.title}</CardTitle>
          <CardDescription>{forgotPassword.description}</CardDescription>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form className="space-y-8" onSubmit={form.handleSubmit(onSubmit)}>
              <div className="grid gap-6">
                <div className="grid gap-3">
                  <FormField
                    control={form.control}
                    name="email"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>{forgotPassword.emailLabel}</FormLabel>
                        <FormControl>
                          <Input
                            placeholder={forgotPassword.emailPlaceholder}
                            {...field}
                          />
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
                    forgotPassword.submitCta
                  )}
                </Button>
              </div>
              <div className="text-center text-sm">
                {forgotPassword.noAccount}{" "}
                <Link className="underline underline-offset-4" href="/signup">
                  {forgotPassword.signupLink}
                </Link>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
      <div className="text-balance text-center text-muted-foreground text-xs *:[a]:underline *:[a]:underline-offset-4 *:[a]:hover:text-primary">
        {forgotPassword.agreePrefix}
        <Link href="/terms">{forgotPassword.termsOfService}</Link>
        {forgotPassword.agreeLinkSeparator}
        <Link href="/privacy">{forgotPassword.privacyPolicy}</Link>
        {forgotPassword.agreeSuffix}
      </div>
    </div>
  );
};
