import { beforeEach, describe, expect, it } from "@jest/globals";

import { MockConfig } from "@/services/mock-config";
import { fetchSeatMap } from "@/services/seats";
import { fetchTickets, purchaseTicket } from "@/services/tickets";

describe("purchaseTicket", () => {
  beforeEach(() => {
    MockConfig.alwaysFailPurchase = false;
    MockConfig.simulateNetworkErrors = false;
  });

  it("should return a ticket with the correct total when purchasing available seats", async () => {
    const result = await purchaseTicket({
      movieId: "wilder-hours",
      showtimeId: "wilder-hours-d0-1400",
      seatIds: ["A-1", "A-2"],
    });

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.seatIds).toEqual(["A-1", "A-2"]);
      expect(result.data.totalUsd).toBe(25);
      expect(result.data.bookingCode).toHaveLength(8);
    }
  });

  it("should return SEATS_TAKEN when purchasing a seat that was already reserved", async () => {
    const result = await purchaseTicket({
      movieId: "nebula-drift",
      showtimeId: "nebula-drift-d0-1800",
      seatIds: ["C-3"],
    });

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe("SEATS_TAKEN");
    }
  });

  it("should mark the seat as reserved after a successful purchase", async () => {
    const showtimeId = "iron-tide-d2-2100";
    await purchaseTicket({ movieId: "iron-tide", showtimeId, seatIds: ["B-8"] });

    const seatMapResult = await fetchSeatMap(showtimeId);
    expect(seatMapResult.ok).toBe(true);
    if (seatMapResult.ok) {
      expect(seatMapResult.data.reservedSeatIds).toContain("B-8");
    }
  });

  it("should return SEATS_TAKEN for every purchase when alwaysFailPurchase is enabled", async () => {
    MockConfig.alwaysFailPurchase = true;
    const result = await purchaseTicket({
      movieId: "wilder-hours",
      showtimeId: "wilder-hours-d1-1400",
      seatIds: ["A-3"],
    });
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe("SEATS_TAKEN");
    }
  });
});

describe("fetchTickets", () => {
  beforeEach(() => {
    MockConfig.alwaysFailPurchase = false;
    MockConfig.simulateNetworkErrors = false;
  });

  it("should include a purchased ticket in the returned list", async () => {
    await purchaseTicket({
      movieId: "glass-marathon",
      showtimeId: "glass-marathon-d0-1400",
      seatIds: ["D-4"],
    });

    const result = await fetchTickets();
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.some((ticket) => ticket.seatIds.includes("D-4"))).toBe(true);
    }
  });
});
