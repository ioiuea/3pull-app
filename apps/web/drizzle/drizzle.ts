import { config } from "dotenv";
import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import { schema } from "./schema";

config({ path: ".env" }); // or .env.local

const databaseUrl = process.env.DATABASE_URL;
const pool = new Pool({
  connectionString: databaseUrl,
  ssl: {
    rejectUnauthorized: true,
  },
});

export const db = drizzle(pool, { schema });
