import { describe, expect, it } from "@jest/globals";

import { calculateSeatPrice, calculateTotal } from "@/services/pricing";
import type { Seat } from "@/types/seat";

function seat(id: string, section: Seat["section"]): Seat {
  const [row, numberPart] = id.split("-");
  return { id, row, number: Number(numberPart), section };
}

describe("calculateSeatPrice", () => {
  it("should return the base price for a standard seat", () => {
    expect(calculateSeatPrice(seat("C-3", "standard"), 12.5)).toBe(12.5);
  });

  it("should return 1.5x the base price for a vip seat", () => {
    expect(calculateSeatPrice(seat("G-3", "vip"), 12.5)).toBe(18.75);
  });

  it("should round a vip seat price with fractional cents to 2 decimal places", () => {
    expect(calculateSeatPrice(seat("G-3", "vip"), 12.33)).toBe(18.5);
  });
});

describe("calculateTotal", () => {
  it("should return 0 when no seats are selected", () => {
    expect(calculateTotal([], 12.5)).toBe(0);
  });

  it("should sum standard and vip seats at their own rates", () => {
    const seats = [seat("C-3", "standard"), seat("G-1", "vip")];
    expect(calculateTotal(seats, 12.5)).toBe(31.25);
  });
});
