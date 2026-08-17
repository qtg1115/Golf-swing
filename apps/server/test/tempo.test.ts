import { describe, expect, it } from "vitest";
import { computeTempo, IDEAL_RATIO } from "../src/tempo.js";

describe("computeTempo", () => {
  it("rates a classic 3:1 swing as ideal with a perfect score", () => {
    const result = computeTempo({ backswingMs: 900, downswingMs: 300 });
    expect(result.ratio).toBe(IDEAL_RATIO);
    expect(result.rating).toBe("ideal");
    expect(result.score).toBe(100);
  });

  it("flags an over-quick transition", () => {
    const result = computeTempo({ backswingMs: 600, downswingMs: 300 });
    expect(result.ratio).toBe(2);
    expect(result.rating).toBe("too-quick");
    expect(result.score).toBeLessThan(100);
  });

  it("flags a sluggish downswing as too slow", () => {
    const result = computeTempo({ backswingMs: 1000, downswingMs: 200 });
    expect(result.ratio).toBe(5);
    expect(result.rating).toBe("too-slow");
  });

  it("rejects non-positive durations", () => {
    expect(() => computeTempo({ backswingMs: 0, downswingMs: 300 })).toThrow();
    expect(() => computeTempo({ backswingMs: 900, downswingMs: -1 })).toThrow();
  });
});
