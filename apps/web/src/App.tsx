import { useCallback, useEffect, useMemo, useState } from "react";
import { createSwing, fetchSwings } from "./api.js";
import type { Rating, SwingRecord } from "./types.js";

const CLUBS = ["Driver", "3 Wood", "5 Iron", "7 Iron", "9 Iron", "Pitching Wedge"];

type Phase = "idle" | "backswing" | "downswing";

const RATING_LABELS: Record<Rating, string> = {
  "too-quick": "Too quick",
  quick: "A touch quick",
  ideal: "Tour tempo",
  slow: "A touch slow",
  "too-slow": "Too slow",
};

function ratingClass(rating: Rating): string {
  if (rating === "ideal") return "pill pill--ideal";
  if (rating === "quick" || rating === "slow") return "pill pill--warn";
  return "pill pill--bad";
}

export default function App() {
  const [club, setClub] = useState<string>(CLUBS[0]);
  const [phase, setPhase] = useState<Phase>("idle");
  const [takeawayAt, setTakeawayAt] = useState<number | null>(null);
  const [topAt, setTopAt] = useState<number | null>(null);

  const [swings, setSwings] = useState<SwingRecord[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [saving, setSaving] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [lastSaved, setLastSaved] = useState<SwingRecord | null>(null);

  const refresh = useCallback(async () => {
    try {
      setError(null);
      setSwings(await fetchSwings());
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load swings");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const save = useCallback(
    async (backswingMs: number, downswingMs: number) => {
      setSaving(true);
      setError(null);
      try {
        const record = await createSwing({ club, backswingMs, downswingMs });
        setLastSaved(record);
        await refresh();
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to save swing");
      } finally {
        setSaving(false);
      }
    },
    [club, refresh],
  );

  const tap = useCallback(() => {
    const now = performance.now();
    if (phase === "idle") {
      setTakeawayAt(now);
      setTopAt(null);
      setPhase("backswing");
      return;
    }
    if (phase === "backswing") {
      setTopAt(now);
      setPhase("downswing");
      return;
    }
    // phase === "downswing" -> this tap is impact
    if (takeawayAt !== null && topAt !== null) {
      const backswingMs = topAt - takeawayAt;
      const downswingMs = now - topAt;
      void save(backswingMs, downswingMs);
    }
    setPhase("idle");
    setTakeawayAt(null);
    setTopAt(null);
  }, [phase, takeawayAt, topAt, save]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.code === "Space") {
        e.preventDefault();
        tap();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [tap]);

  const buttonLabel = useMemo(() => {
    switch (phase) {
      case "idle":
        return "Start · Takeaway";
      case "backswing":
        return "Top of Backswing";
      case "downswing":
        return "Impact!";
    }
  }, [phase]);

  const stats = useMemo(() => {
    if (swings.length === 0) return null;
    const avgRatio =
      swings.reduce((sum, s) => sum + s.ratio, 0) / swings.length;
    const avgScore =
      swings.reduce((sum, s) => sum + s.score, 0) / swings.length;
    return {
      count: swings.length,
      avgRatio: Math.round(avgRatio * 100) / 100,
      avgScore: Math.round(avgScore),
    };
  }, [swings]);

  return (
    <div className="page">
      <header className="header">
        <h1>
          <span aria-hidden>⛳</span> Golf Swing Tempo Trainer
        </h1>
        <p className="subtitle">
          Tap through takeaway → top → impact. Tour pros swing at a 3:1
          backswing-to-downswing tempo.
        </p>
      </header>

      <main className="grid">
        <section className="card capture">
          <label className="field">
            <span>Club</span>
            <select
              value={club}
              onChange={(e) => setClub(e.target.value)}
              disabled={phase !== "idle"}
            >
              {CLUBS.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </label>

          <button
            type="button"
            className={`tap tap--${phase}`}
            onClick={tap}
            disabled={saving}
          >
            {buttonLabel}
          </button>

          <p className="hint">
            Tip: you can also press <kbd>Space</kbd> to tap.
          </p>

          {lastSaved && (
            <div className="result">
              <div className="result__ratio">
                {lastSaved.ratio.toFixed(2)}
                <span>:1</span>
              </div>
              <div className="result__meta">
                <span className={ratingClass(lastSaved.rating)}>
                  {RATING_LABELS[lastSaved.rating]}
                </span>
                <span className="muted">
                  Backswing {lastSaved.backswingMs} ms · Downswing{" "}
                  {lastSaved.downswingMs} ms · Score {lastSaved.score}
                </span>
              </div>
            </div>
          )}

          {error && <p className="error">{error}</p>}
        </section>

        <section className="card">
          <div className="card__head">
            <h2>Session history</h2>
            {stats && (
              <div className="stats">
                <span>
                  <strong>{stats.count}</strong> swings
                </span>
                <span>
                  avg <strong>{stats.avgRatio.toFixed(2)}:1</strong>
                </span>
                <span>
                  avg score <strong>{stats.avgScore}</strong>
                </span>
              </div>
            )}
          </div>

          {loading ? (
            <p className="muted">Loading…</p>
          ) : swings.length === 0 ? (
            <p className="muted">No swings yet — capture your first one!</p>
          ) : (
            <ul className="history">
              {swings.map((s) => (
                <li key={s.id} className="history__row">
                  <div className="history__club">{s.club}</div>
                  <div className="history__ratio">{s.ratio.toFixed(2)}:1</div>
                  <span className={ratingClass(s.rating)}>
                    {RATING_LABELS[s.rating]}
                  </span>
                  <div className="history__time">
                    {new Date(s.createdAt).toLocaleTimeString()}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>
      </main>
    </div>
  );
}
