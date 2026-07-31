import type { Showtime } from "@/types/movie";
import { delay } from "./delay";
import { SHOWTIMES } from "./mock-data/showtimes";
import { err, ok, type Result } from "./result";

export function findShowtimeByIdSync(showtimeId: string): Showtime | undefined {
  return SHOWTIMES.find((candidate) => candidate.id === showtimeId);
}

export async function fetchShowtimes(
  movieId: string,
): Promise<Result<Showtime[]>> {
  await delay();
  const showtimes = SHOWTIMES.filter(
    (showtime) => showtime.movieId === movieId,
  );
  if (showtimes.length === 0) {
    return err("NOT_FOUND", `No showtimes for movie: ${movieId}`);
  }
  return ok(showtimes);
}

export async function fetchShowtimeById(
  showtimeId: string,
): Promise<Result<Showtime>> {
  await delay();
  const showtime = findShowtimeByIdSync(showtimeId);
  if (!showtime) {
    return err("NOT_FOUND", `Showtime not found: ${showtimeId}`);
  }
  return ok(showtime);
}

export async function fetchAllShowtimes(): Promise<Result<Showtime[]>> {
  await delay();
  return ok(SHOWTIMES);
}
