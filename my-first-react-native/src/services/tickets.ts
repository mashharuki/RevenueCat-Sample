import type { Ticket } from "@/types/ticket";
import { delay } from "./delay";
import { MockConfig } from "./mock-config";
import { calculateTotal } from "./pricing";
import { err, ok, type Result } from "./result";
import { fetchSeatMap, markSeatsReserved, parseSeatId } from "./seats";
import { findShowtimeByIdSync } from "./showtimes";

export type PurchaseInput = {
  movieId: string;
  showtimeId: string;
  seatIds: string[];
};

const ticketsStore: Ticket[] = [];

const BOOKING_CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

function generateBookingCode(): string {
  let code = "";
  for (let i = 0; i < 8; i += 1) {
    code +=
      BOOKING_CODE_CHARS[Math.floor(Math.random() * BOOKING_CODE_CHARS.length)];
  }
  return code;
}

function generateTicketId(): string {
  return `tkt_${Date.now()}_${Math.floor(Math.random() * 1_000_000)}`;
}

export async function purchaseTicket(
  input: PurchaseInput,
): Promise<Result<Ticket>> {
  await delay();

  if (MockConfig.alwaysFailPurchase) {
    return err(
      "SEATS_TAKEN",
      "One or more selected seats were just booked by someone else.",
    );
  }

  const showtime = findShowtimeByIdSync(input.showtimeId);
  if (!showtime) {
    return err("NOT_FOUND", `Showtime not found: ${input.showtimeId}`);
  }

  const seatMapResult = await fetchSeatMap(input.showtimeId);
  if (!seatMapResult.ok) {
    return seatMapResult;
  }

  const alreadyTaken = input.seatIds.some((seatId) =>
    seatMapResult.data.reservedSeatIds.includes(seatId),
  );
  if (alreadyTaken) {
    return err(
      "SEATS_TAKEN",
      "One or more selected seats were just booked by someone else.",
    );
  }

  const seats = input.seatIds.map((seatId) =>
    parseSeatId(seatId, seatMapResult.data.vipRows),
  );
  const totalUsd = calculateTotal(seats, showtime.priceUsd);

  markSeatsReserved(input.showtimeId, input.seatIds);

  const ticket: Ticket = {
    id: generateTicketId(),
    movieId: input.movieId,
    showtimeId: input.showtimeId,
    seatIds: input.seatIds,
    totalUsd,
    purchasedAt: new Date().toISOString(),
    bookingCode: generateBookingCode(),
  };
  ticketsStore.push(ticket);

  return ok(ticket);
}

export async function fetchTickets(): Promise<Result<Ticket[]>> {
  await delay();
  return ok([...ticketsStore]);
}
