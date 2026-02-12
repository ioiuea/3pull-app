import { describe, expect, it } from "vitest"

import { cn } from "@/lib/utils"

describe("cn", () => {
  it("merges class names and resolves tailwind conflicts", () => {
    const result = cn("px-2", "text-sm", "px-4")

    expect(result).toBe("text-sm px-4")
  })
})
