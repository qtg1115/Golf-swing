export type Rating = "too-quick" | "quick" | "ideal" | "slow" | "too-slow";

export interface SwingRecord {
  id: string;
  club: string;
  createdAt: string;
  backswingMs: number;
  downswingMs: number;
  ratio: number;
  score: number;
  rating: Rating;
}

export interface CreateSwingInput {
  club: string;
  backswingMs: number;
  downswingMs: number;
}
