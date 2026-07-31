import type { Showtime } from "@/types/movie";

import { MOVIES } from "./movies";

const DAY_OFFSETS = [0, 1, 2] as const;
const TIME_SLOTS = ["14:00", "18:00", "21:00"] as const;
const HALLS = ["Hall A", "Hall B"] as const;
const BASE_PRICE_USD = 12.5;

function addDaysIso(daysFromToday: number): string {
  const date = new Date();
  date.setDate(date.getDate() + daysFromToday);
  return date.toISOString().slice(0, 10);
}

export const SHOWTIMES: Showtime[] = MOVIES.flatMap((movie, movieIndex) =>
  DAY_OFFSETS.flatMap((dayOffset) =>
    TIME_SLOTS.map((time, timeIndex) => ({
      id: `${movie.id}-d${dayOffset}-${time.replace(":", "")}`,
      movieId: movie.id,
      date: addDaysIso(dayOffset),
      time,
      hall: HALLS[(movieIndex + timeIndex) % HALLS.length],
      priceUsd: BASE_PRICE_USD,
    })),
  ),
);
