import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { createApp } from "./app.js";
import { SwingStore } from "./store.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

const PORT = Number(process.env.PORT ?? 3001);
const DATA_FILE = process.env.DATA_FILE ?? resolve(__dirname, "../data/swings.json");

const store = new SwingStore(DATA_FILE);
const app = createApp({ store });

app.listen(PORT, () => {
  console.log(`golf-swing API listening on http://localhost:${PORT}`);
  console.log(`persisting swings to ${DATA_FILE}`);
});
