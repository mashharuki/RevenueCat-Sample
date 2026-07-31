import type { Seat, SeatMap } from "@/types/seat";
import { delay } from "./delay";
import { err, ok, type Result } from "./result";
import { findShowtimeByIdSync } from "./showtimes";

const ROWS = ["A", "B", "C", "D", "E", "F", "G", "H"];
const SEATS_PER_ROW = 12;
const VIP_ROWS = ["G", "H"];

const INITIAL_RESERVED_SEATS: Record<string, string[]> = {
  "nebula-drift-d0-1800": ["C-3", "C-4", "D-6", "D-7", "F-2"],
  "crimson-hour-d0-1800": ["B-5", "B-6", "E-9"],
  "last-cartographer-d1-1400": ["A-1", "A-2", "G-3"],
};

const seatReservationStore = new Map<string, Set<string>>();

export function generateSeatMap(
  showtimeId: string,
  reservedSeatIds: string[],
): SeatMap {
  return {
    showtimeId,
    rows: ROWS,
    seatsPerRow: SEATS_PER_ROW,
    vipRows: VIP_ROWS,
    reservedSeatIds,
  };
}

export function parseSeatId(seatId: string, vipRows: string[]): Seat {
  const [row, numberPart] = seatId.split("-");
  return {
    id: seatId,
    row,
    number: Number(numberPart),
    section: vipRows.includes(row) ? "vip" : "standard",
  };
}

function getReservedSeatIds(showtimeId: string): string[] {
  const existing = seatReservationStore.get(showtimeId);
  if (existing) {
    return Array.from(existing);
  }
  return INITIAL_RESERVED_SEATS[showtimeId] ?? [];
}

export function markSeatsReserved(showtimeId: string, seatIds: string[]): void {
  const current = new Set(getReservedSeatIds(showtimeId));
  for (const seatId of seatIds) {
    current.add(seatId);
  }
  seatReservationStore.set(showtimeId, current);
}

export async function fetchSeatMap(
  showtimeId: string,
): Promise<Result<SeatMap>> {
  await delay();
  const showtime = findShowtimeByIdSync(showtimeId);
  if (!showtime) {
    return err("NOT_FOUND", `Showtime not found: ${showtimeId}`);
  }
  return ok(generateSeatMap(showtimeId, getReservedSeatIds(showtimeId)));
}
