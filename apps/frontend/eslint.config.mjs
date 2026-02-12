import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
    // ORM
    "drizzle/**",
    // Generated/third-party style UI primitives are excluded from CI linting.
    "components/ui/**",
    // Unit Test
    "test/**"
  ]),
]);

export default eslintConfig;
