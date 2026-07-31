import { describe, expect, it } from "@jest/globals";

import { fetchSeatMap, generateSeatMap, parseSeatId } from "@/services/seats";

describe("generateSeatMap", () => {
  it("should return 8 rows of 12 seats when generating a seat map", () => {
    const seatMap = generateSeatMap("showtime-1", []);
    expect(seatMap.rows).toHaveLength(8);
    expect(seatMap.seatsPerRow).toBe(12);
  });

  it("should mark rows G and H as VIP rows", () => {
    const seatMap = generateSeatMap("showtime-1", []);
    expect(seatMap.vipRows).toEqual(["G", "H"]);
  });

  it("should reflect the reserved seat ids passed in", () => {
    const seatMap = generateSeatMap("showtime-1", ["C-3", "C-4"]);
    expect(seatMap.reservedSeatIds).toEqual(["C-3", "C-4"]);
  });
});

describe("parseSeatId", () => {
  it("should mark a seat in a VIP row as vip section when parsing", () => {
    const seat = parseSeatId("G-5", ["G", "H"]);
    expect(seat).toEqual({ id: "G-5", row: "G", number: 5, section: "vip" });
  });

  it("should mark a seat in a non-VIP row as standard section when parsing", () => {
    const seat = parseSeatId("C-9", ["G", "H"]);
    expect(seat.section).toBe("standard");
  });
});

describe("fetchSeatMap", () => {
  it("should return NOT_FOUND when the showtime does not exist", async () => {
    const result = await fetchSeatMap("does-not-exist");
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe("NOT_FOUND");
    }
  });
});
