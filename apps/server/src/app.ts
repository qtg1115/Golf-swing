import cors from "cors";
import express, { type Express } from "express";
import { SwingStore } from "./store.js";

export interface AppOptions {
  store: SwingStore;
}

export function createApp({ store }: AppOptions): Express {
  const app = express();
  app.use(cors());
  app.use(express.json());

  app.get("/api/health", (_req, res) => {
    res.json({ status: "ok", service: "golf-swing-server" });
  });

  app.get("/api/swings", async (_req, res, next) => {
    try {
      res.json(await store.list());
    } catch (err) {
      next(err);
    }
  });

  app.post("/api/swings", async (req, res, next) => {
    try {
      const { club, backswingMs, downswingMs } = req.body ?? {};
      if (typeof backswingMs !== "number" || typeof downswingMs !== "number") {
        res.status(400).json({
          error: "backswingMs and downswingMs are required numbers (in ms).",
        });
        return;
      }
      if (backswingMs <= 0 || downswingMs <= 0) {
        res.status(400).json({
          error: "backswingMs and downswingMs must be greater than zero.",
        });
        return;
      }
      const record = await store.create({ club, backswingMs, downswingMs });
      res.status(201).json(record);
    } catch (err) {
      next(err);
    }
  });

  app.delete("/api/swings", async (_req, res, next) => {
    try {
      await store.clear();
      res.status(204).end();
    } catch (err) {
      next(err);
    }
  });

  return app;
}
