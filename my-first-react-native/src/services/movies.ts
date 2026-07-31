import { delay } from "./delay";
import { MockConfig } from "./mock-config";
import { MOVIES } from "./mock-data/movies";
import { err, ok, type Result } from "./result";

import type { Movie } from "@/types/movie";

export async function fetchMovies(): Promise<Result<Movie[]>> {
  await delay();
  if (MockConfig.simulateNetworkErrors && Math.random() < 0.3) {
    return err("NETWORK", "Could not reach the movie catalog.");
  }
  return ok(MOVIES);
}

export async function fetchMovieById(id: string): Promise<Result<Movie>> {
  await delay();
  const movie = MOVIES.find((candidate) => candidate.id === id);
  if (!movie) {
    return err("NOT_FOUND", `Movie not found: ${id}`);
  }
  return ok(movie);
}
