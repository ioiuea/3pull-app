import type { MetadataRoute } from "next";

const isSearchIndexingBlocked = process.env.BLOCK_SEARCH_INDEXING === "true";

const robots = (): MetadataRoute.Robots => {
  if (isSearchIndexingBlocked) {
    return {
      rules: {
        userAgent: "*",
        disallow: "/",
      },
    };
  }

  return {
    rules: {
      userAgent: "*",
      allow: "/",
    },
  };
};

export default robots;
