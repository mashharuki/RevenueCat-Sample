import type { Seat } from "@/types/seat";

const VIP_MULTIPLIER = 1.5;

function roundToCents(amount: number): number {
  return Math.round(amount * 100) / 100;
}

export function calculateSeatPrice(seat: Seat, basePriceUsd: number): number {
  const rawPrice =
    seat.section === "vip" ? basePriceUsd * VIP_MULTIPLIER : basePriceUsd;
  return roundToCents(rawPrice);
}

export function calculateTotal(seats: Seat[], basePriceUsd: number): number {
  const total = seats.reduce(
    (sum, current) => sum + calculateSeatPrice(current, basePriceUsd),
    0,
  );
  return roundToCents(total);
}
