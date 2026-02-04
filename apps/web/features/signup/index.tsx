"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
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
import { signUp } from "@/server/users";

type Dictionary = typeof import("@/dictionaries/en.json");

type SignupClientProps = {
  dict: Dictionary;
};

const formSchema = z.object({
  username: z.string().min(3),
  email: z.email(),
  password: z.string().min(8),
});

export const SignupClient = ({ dict }: SignupClientProps) => {
  const { signup } = dict;
  const [isLoading, setIsLoading] = useState(false);

  const router = useRouter();
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      username: "",
      email: "",
      password: "",
    },
  });

  async function onSubmit(values: z.infer<typeof formSchema>) {
    setIsLoading(true);

    const { success, message } = await signUp(
      values.email,
      values.password,
      values.username,
    );

    if (success) {
      toast.success(
        `${message as string} Please check your email for verification.`,
      );
      router.push("/dashboard");
    } else {
      toast.error(message as string);
    }

    setIsLoading(false);
  }

  return (
    <div className="flex flex-col gap-6">
      <Card>
        <CardHeader className="text-center">
          <CardTitle className="text-xl">{signup.welcome}</CardTitle>
          <CardDescription>{signup.signupWithEmailDescription}</CardDescription>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form className="space-y-8" onSubmit={form.handleSubmit(onSubmit)}>
              <div className="grid gap-6">
                <div className="grid gap-6">
                  <div className="grid gap-3">
                    <FormField
                      control={form.control}
                      name="username"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>{signup.usernameLabel}</FormLabel>
                          <FormControl>
                            <Input
                              placeholder={signup.usernamePlaceholder}
                              {...field}
                            />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />

                    <FormField
                      control={form.control}
                      name="email"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>{signup.emailLabel}</FormLabel>
                          <FormControl>
                            <Input
                              placeholder={signup.emailPlaceholder}
                              {...field}
                            />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                  </div>
                  <div className="grid gap-3">
                    <div className="flex flex-col gap-2">
                      <FormField
                        control={form.control}
                        name="password"
                        render={({ field }) => (
                          <FormItem>
                            <FormLabel>{signup.passwordLabel}</FormLabel>
                            <FormControl>
                              <Input
                                placeholder={signup.passwordPlaceholder}
                                {...field}
                                type="password"
                              />
                            </FormControl>
                            <FormMessage />
                          </FormItem>
                        )}
                      />
                      <Link
                        className="ml-auto text-sm underline-offset-4 hover:underline"
                        href="/forgot-password"
                      >
                        {signup.forgotPassword}
                      </Link>
                    </div>
                  </div>
                  <Button className="w-full" disabled={isLoading} type="submit">
                    {isLoading ? (
                      <Loader2 className="size-4 animate-spin" />
                    ) : (
                      signup.signupCta
                    )}
                  </Button>
                </div>
                <div className="text-center text-sm">
                  {signup.alreadyHaveAccount}{" "}
                  <Link className="underline underline-offset-4" href="/login">
                    {signup.loginLink}
                  </Link>
                </div>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
      <div className="text-balance text-center text-muted-foreground text-xs *:[a]:underline *:[a]:underline-offset-4 *:[a]:hover:text-primary">
        {signup.agreePrefix}
        <Link href="/terms">{signup.termsOfService}</Link>
        {signup.agreeLinkSeparator}
        <Link href="/privacy">{signup.privacyPolicy}</Link>
        {signup.agreeSuffix}
      </div>
    </div>
  );
};
