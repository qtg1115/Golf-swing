export interface SwingTimings {
  /** Milliseconds from takeaway to the top of the backswing. */
  backswingMs: number;
  /** Milliseconds from the top of the backswing to impact. */
  downswingMs: number;
}

export interface TempoResult extends SwingTimings {
  /** Backswing-to-downswing ratio (e.g. 3.0 means 3:1). */
  ratio: number;
  /** How close the ratio is to the classic 3:1 tour tempo, as a 0–100 score. */
  score: number;
  /** Human-friendly assessment of the tempo. */
  rating: "too-quick" | "quick" | "ideal" | "slow" | "too-slow";
}

/** The tempo most tour players exhibit: a 3:1 backswing-to-downswing ratio. */
export const IDEAL_RATIO = 3.0;

export function computeTempo({ backswingMs, downswingMs }: SwingTimings): TempoResult {
  if (!Number.isFinite(backswingMs) || !Number.isFinite(downswingMs)) {
    throw new Error("backswingMs and downswingMs must be finite numbers");
  }
  if (backswingMs <= 0 || downswingMs <= 0) {
    throw new Error("backswingMs and downswingMs must be greater than zero");
  }

  const ratio = backswingMs / downswingMs;

  // Score decays as the ratio drifts from the ideal 3:1, clamped to 0–100.
  const deviation = Math.abs(ratio - IDEAL_RATIO);
  const score = Math.max(0, Math.round(100 - deviation * 40));

  let rating: TempoResult["rating"];
  if (ratio < 2.3) rating = "too-quick";
  else if (ratio < 2.75) rating = "quick";
  else if (ratio <= 3.25) rating = "ideal";
  else if (ratio <= 3.7) rating = "slow";
  else rating = "too-slow";

  return {
    backswingMs: Math.round(backswingMs),
    downswingMs: Math.round(downswingMs),
    ratio: Math.round(ratio * 100) / 100,
    score,
    rating,
  };
}
