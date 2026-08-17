import { randomUUID } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import { computeTempo, type TempoResult } from "./tempo.js";

export interface SwingRecord extends TempoResult {
  id: string;
  club: string;
  createdAt: string;
}

export interface CreateSwingInput {
  club: string;
  backswingMs: number;
  downswingMs: number;
}

/**
 * Tiny JSON-file backed store. This is intentionally simple so the app runs
 * end-to-end with zero external services in a fresh Cloud Agent environment.
 */
export class SwingStore {
  private records: SwingRecord[] = [];
  private loaded = false;

  constructor(private readonly filePath: string) {}

  private async ensureLoaded(): Promise<void> {
    if (this.loaded) return;
    try {
      const raw = await readFile(this.filePath, "utf8");
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) this.records = parsed;
    } catch (err) {
      if ((err as NodeJS.ErrnoException).code !== "ENOENT") throw err;
      this.records = [];
    }
    this.loaded = true;
  }

  private async persist(): Promise<void> {
    await mkdir(dirname(this.filePath), { recursive: true });
    await writeFile(this.filePath, JSON.stringify(this.records, null, 2), "utf8");
  }

  async list(): Promise<SwingRecord[]> {
    await this.ensureLoaded();
    return [...this.records].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  }

  async create(input: CreateSwingInput): Promise<SwingRecord> {
    await this.ensureLoaded();
    const club = input.club?.trim() || "Driver";
    const tempo = computeTempo({
      backswingMs: input.backswingMs,
      downswingMs: input.downswingMs,
    });
    const record: SwingRecord = {
      id: randomUUID(),
      club,
      createdAt: new Date().toISOString(),
      ...tempo,
    };
    this.records.push(record);
    await this.persist();
    return record;
  }

  async clear(): Promise<void> {
    await this.ensureLoaded();
    this.records = [];
    await this.persist();
  }
}
