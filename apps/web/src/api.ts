import type { CreateSwingInput, SwingRecord } from "./types.js";

async function handle<T>(res: Response): Promise<T> {
  if (!res.ok) {
    let message = `Request failed with ${res.status}`;
    try {
      const body = await res.json();
      if (body?.error) message = body.error;
    } catch {
      // ignore non-JSON error bodies
    }
    throw new Error(message);
  }
  return res.json() as Promise<T>;
}

export async function fetchSwings(): Promise<SwingRecord[]> {
  return handle<SwingRecord[]>(await fetch("/api/swings"));
}

export async function createSwing(input: CreateSwingInput): Promise<SwingRecord> {
  const res = await fetch("/api/swings", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  });
  return handle<SwingRecord>(res);
}
