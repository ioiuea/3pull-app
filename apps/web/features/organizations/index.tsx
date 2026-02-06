"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { authClient } from "@/lib/auth-client";

type Dictionary = typeof import("@/dictionaries/en.json");

type OrganizationsClientProps = {
  dict: Dictionary;
};

export const OrganizationsClient = ({ dict }: OrganizationsClientProps) => {
  const { organizations } = dict;
  const [isLoading, setIsLoading] = useState(false);

  const formSchema = z.object({
    name: z
      .string()
      .min(2, organizations.form.nameMin)
      .max(50, organizations.form.nameMax),
    slug: z
      .string()
      .min(2, organizations.form.slugMin)
      .max(50, organizations.form.slugMax)
      .regex(/^[a-z0-9-]+$/, organizations.form.slugPattern),
  });

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: "",
      slug: "",
    },
  });

  const onSubmit = async (values: z.infer<typeof formSchema>) => {
    try {
      setIsLoading(true);
      await authClient.organization.create({
        name: values.name,
        slug: values.slug,
      });

      toast.success(organizations.createSuccess);
    } catch (error) {
      console.error(error);
      toast.error(organizations.createError);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Form {...form}>
      <form className="space-y-4" onSubmit={form.handleSubmit(onSubmit)}>
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>{organizations.form.nameLabel}</FormLabel>
              <FormControl>
                <Input
                  placeholder={organizations.form.namePlaceholder}
                  {...field}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="slug"
          render={({ field }) => (
            <FormItem>
              <FormLabel>{organizations.form.slugLabel}</FormLabel>
              <FormControl>
                <Input
                  placeholder={organizations.form.slugPlaceholder}
                  {...field}
                />
              </FormControl>
              <FormDescription>{organizations.form.slugHint}</FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button disabled={isLoading} type="submit">
          {isLoading ? (
            <Loader2 className="size-4 animate-spin" />
          ) : (
            organizations.form.submitCta
          )}
        </Button>
      </form>
    </Form>
  );
};
