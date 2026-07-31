import { describe, expect, it } from "@jest/globals";

import { bookingReducer, initialBookingState } from "@/context/booking-context";

describe("bookingReducer", () => {
  it("should set movieId and showtimeId and reset seats when selecting a showtime", () => {
    const state = bookingReducer(initialBookingState, {
      type: "selectShowtime",
      movieId: "nebula-drift",
      showtimeId: "nebula-drift-d0-1800",
    });
    expect(state).toEqual({
      movieId: "nebula-drift",
      showtimeId: "nebula-drift-d0-1800",
      selectedSeatIds: [],
    });
  });

  it("should add a seat when toggling an unselected seat", () => {
    const state = bookingReducer(initialBookingState, { type: "toggleSeat", seatId: "C-3" });
    expect(state.selectedSeatIds).toEqual(["C-3"]);
  });

  it("should remove a seat when toggling an already-selected seat", () => {
    const withSeat = { ...initialBookingState, selectedSeatIds: ["C-3"] };
    const state = bookingReducer(withSeat, { type: "toggleSeat", seatId: "C-3" });
    expect(state.selectedSeatIds).toEqual([]);
  });

  it("should not add a seat beyond the 6-seat limit", () => {
    const fullState = {
      ...initialBookingState,
      selectedSeatIds: ["A-1", "A-2", "A-3", "A-4", "A-5", "A-6"],
    };
    const state = bookingReducer(fullState, { type: "toggleSeat", seatId: "A-7" });
    expect(state.selectedSeatIds).toHaveLength(6);
    expect(state.selectedSeatIds).not.toContain("A-7");
  });

  it("should reset to the initial state when clearing the booking", () => {
    const dirtyState = { movieId: "x", showtimeId: "y", selectedSeatIds: ["A-1"] };
    const state = bookingReducer(dirtyState, { type: "clearBooking" });
    expect(state).toEqual(initialBookingState);
  });
});
