"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { z } from "zod";
import { motion } from "motion/react";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { type Locale } from "@/lib/i18n/locales";

type Dictionary = typeof import("@/dictionaries/en.json");

type SampleZodClientProps = {
  dict: Dictionary;
  lang: Locale;
};

type FormValues = {
  name: string;
  age: string;
};

type FormResult = {
  ok: boolean;
  message: string;
};

export const SampleZodClient = ({ dict, lang }: SampleZodClientProps) => {
  const { sample } = dict;
  const [formValues, setFormValues] = useState<FormValues>({
    name: "",
    age: "",
  });
  const [formResult, setFormResult] = useState<FormResult | null>(null);

  const formSchema = useMemo(
    () =>
      z.object({
        name: z.string().min(2, sample.zod.validation.nameMin),
        age: z.coerce
          .number()
          .int(sample.zod.validation.ageInteger)
          .min(13, sample.zod.validation.ageMin)
          .max(120, sample.zod.validation.ageMax),
      }),
    [sample.zod.validation],
  );

  const formErrors = useMemo(() => {
    if (!formResult || formResult.ok) {
      return [];
    }
    return formResult.message.split("\n");
  }, [formResult]);

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const parsed = formSchema.safeParse({
      name: formValues.name,
      age: formValues.age,
    });

    if (!parsed.success) {
      const messages = parsed.error.issues.map((issue) => issue.message);
      setFormResult({ ok: false, message: messages.join("\n") });
      return;
    }

    const successMessage = sample.zod.successMessage
      .replace("{name}", parsed.data.name)
      .replace("{age}", String(parsed.data.age));

    setFormResult({
      ok: true,
      message: successMessage,
    });
  };

  return (
    <div className="min-h-screen bg-linear-to-br from-background via-muted/40 to-muted/70 px-6 py-12 text-foreground">
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="mx-auto flex w-full max-w-3xl flex-col gap-8"
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
              <Badge variant="outline">{sample.zod.badge}</Badge>
            </div>
            <CardTitle className="text-4xl font-semibold tracking-tight">
              {sample.zod.title}
            </CardTitle>
            <p className="text-base leading-7 text-muted-foreground">
              {sample.zod.description}
            </p>
          </CardHeader>
        </Card>

        <motion.section
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
        >
          <Card>
            <CardHeader>
              <CardTitle>{sample.zod.formTitle}</CardTitle>
              <p className="text-sm text-muted-foreground">
                {sample.zod.formDescription}
              </p>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="name-input">{sample.zod.nameLabel}</Label>
                  <Input
                    id="name-input"
                    placeholder={sample.zod.namePlaceholder}
                    value={formValues.name}
                    onChange={(event) =>
                      setFormValues((prev) => ({
                        ...prev,
                        name: event.target.value,
                      }))
                    }
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="age-input">{sample.zod.ageLabel}</Label>
                  <Input
                    id="age-input"
                    placeholder={sample.zod.agePlaceholder}
                    value={formValues.age}
                    onChange={(event) =>
                      setFormValues((prev) => ({
                        ...prev,
                        age: event.target.value,
                      }))
                    }
                  />
                </div>
                <Button type="submit" className="w-full">
                  {sample.zod.submitCta}
                </Button>
              </form>
            </CardContent>
            {formResult && (
              <CardFooter className="flex-col items-start gap-2">
                <Alert
                  variant={formResult.ok ? "default" : "destructive"}
                  className={
                    formResult.ok
                      ? "border-emerald-200 bg-emerald-50 text-emerald-700 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-200"
                      : ""
                  }
                >
                  <AlertTitle>
                    {formResult.ok
                      ? sample.zod.successTitle
                      : sample.zod.errorTitle}
                  </AlertTitle>
                  <AlertDescription>
                    {formResult.ok ? (
                      <p>{formResult.message}</p>
                    ) : (
                      <ul className="list-disc space-y-1 pl-4">
                        {formErrors.map((message) => (
                          <li key={message}>{message}</li>
                        ))}
                      </ul>
                    )}
                  </AlertDescription>
                </Alert>
              </CardFooter>
            )}
          </Card>
        </motion.section>
      </motion.div>
    </div>
  );
};
