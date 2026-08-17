import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { createApp } from "../src/app.js";
import { SwingStore } from "../src/store.js";

describe("swings API", () => {
  let dir: string;
  let app: ReturnType<typeof createApp>;

  beforeEach(async () => {
    dir = await mkdtemp(join(tmpdir(), "golf-swing-test-"));
    const store = new SwingStore(join(dir, "swings.json"));
    app = createApp({ store });
  });

  afterEach(async () => {
    await rm(dir, { recursive: true, force: true });
  });

  it("reports health", async () => {
    const res = await request(app).get("/api/health");
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
  });

  it("creates and lists a swing record end-to-end", async () => {
    const create = await request(app)
      .post("/api/swings")
      .send({ club: "7 Iron", backswingMs: 900, downswingMs: 300 });

    expect(create.status).toBe(201);
    expect(create.body).toMatchObject({
      club: "7 Iron",
      ratio: 3,
      rating: "ideal",
      score: 100,
    });
    expect(create.body.id).toBeTruthy();

    const list = await request(app).get("/api/swings");
    expect(list.status).toBe(200);
    expect(list.body).toHaveLength(1);
    expect(list.body[0].id).toBe(create.body.id);
  });

  it("rejects invalid payloads", async () => {
    const res = await request(app)
      .post("/api/swings")
      .send({ club: "Driver", backswingMs: "nope" });
    expect(res.status).toBe(400);
  });
});
