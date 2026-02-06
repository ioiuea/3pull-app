import Link from "next/link";
import { OrganizationsClient } from "@/features/organizations";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { getDictionary } from "@/lib/dictionaries";
import { type Locale } from "@/lib/i18n";
import { getOrganizations } from "@/server/organizations";

type OrganizationsPageProps = {
  params: Promise<{ lang: Locale }>;
};

const OrganizationsPage = async ({ params }: OrganizationsPageProps) => {
  const { lang } = await params;
  const dict = await getDictionary(lang);
  const { organizations } = dict;
  const orgs = await getOrganizations();

  return (
    <div className="flex h-screen flex-col items-center justify-center gap-2">
      <Dialog>
        <DialogTrigger asChild>
          <Button variant="outline">{organizations.createOrganizationCta}</Button>
        </DialogTrigger>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{organizations.createOrganizationTitle}</DialogTitle>
            <DialogDescription>
              {organizations.createOrganizationDescription}
            </DialogDescription>
          </DialogHeader>
          <OrganizationsClient dict={dict} />
        </DialogContent>
      </Dialog>

      <div className="flex flex-col gap-2">
        <h2 className="font-bold text-2xl">Organizations</h2>
        {orgs.map((org) => (
          <Button asChild key={org.id} variant="outline">
            <Link href={`/${lang}/organizations/${org.slug}`}>
              {org.name}
            </Link>
          </Button>
        ))}
      </div>
    </div>
  );
};

export default OrganizationsPage;
