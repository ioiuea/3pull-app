import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { Member } from "@/drizzle/schema";
import { MembersTableAction } from "@/features/organizations/members-table-action";

type MembersTableProps = {
  members: Member[];
};

export const MembersTable = ({ members }: MembersTableProps) => {
  return (
    <Table>
      <TableCaption>A list of organization members.</TableCaption>
      <TableHeader>
        <TableRow>
          <TableHead className="w-25">Username</TableHead>
          <TableHead>Email</TableHead>
          <TableHead>Role</TableHead>
          <TableHead className="text-right">Actions</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {members.map((member) => (
          <TableRow key={member.id}>
            <TableCell className="font-medium">{member.user.name}</TableCell>
            <TableCell>{member.user.email}</TableCell>
            <TableCell>{member.role}</TableCell>
            <TableCell className="text-right">
              <MembersTableAction memberId={member.id} />
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
};
