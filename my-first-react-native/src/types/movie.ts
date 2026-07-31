export type Movie = {
  id: string;
  title: string;
  tagline: string;
  synopsis: string;
  genres: string[];
  durationMinutes: number;
  rating: number;
  ageRating: string;
  posterGradient: readonly [string, string];
};

export type Showtime = {
  id: string;
  movieId: string;
  date: string;
  time: string;
  hall: string;
  priceUsd: number;
};
