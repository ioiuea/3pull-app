import { OrganizationSwitcherClient } from "@/components/sample-switcher/organization-switcher-client";
import { getOrganizations } from "@/server/organizations";

export const OrganizationSwitcher = async () => {
  const orgs = await getOrganizations();

  return <OrganizationSwitcherClient orgs={orgs} />;
};
