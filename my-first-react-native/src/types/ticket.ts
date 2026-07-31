export type Ticket = {
  id: string;
  movieId: string;
  showtimeId: string;
  seatIds: string[];
  totalUsd: number;
  purchasedAt: string;
  bookingCode: string;
};
