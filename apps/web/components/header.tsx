import { getOrganizations } from "@/server/organizations";
import { Logout } from "./logout";
import { OrganizationSwitcher } from "./organization-switcher";

export async function Header() {
  const organizations = await getOrganizations();

  return (
    <header className="absolute top-0 left-0 flex w-full items-center gap-2 p-4">
      <OrganizationSwitcher organizations={organizations} />
      <Logout />
    </header>
  );
}
