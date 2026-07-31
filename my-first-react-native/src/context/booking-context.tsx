import {
  createContext,
  type Dispatch,
  type ReactNode,
  useContext,
  useReducer,
} from "react";

export type BookingState = {
  movieId: string | null;
  showtimeId: string | null;
  selectedSeatIds: string[];
};

export type BookingAction =
  | { type: "selectShowtime"; movieId: string; showtimeId: string }
  | { type: "toggleSeat"; seatId: string }
  | { type: "clearBooking" };

export const initialBookingState: BookingState = {
  movieId: null,
  showtimeId: null,
  selectedSeatIds: [],
};

const MAX_SELECTED_SEATS = 6;

export function bookingReducer(
  state: BookingState,
  action: BookingAction,
): BookingState {
  switch (action.type) {
    case "selectShowtime":
      return {
        movieId: action.movieId,
        showtimeId: action.showtimeId,
        selectedSeatIds: [],
      };
    case "toggleSeat": {
      const isSelected = state.selectedSeatIds.includes(action.seatId);
      if (isSelected) {
        return {
          ...state,
          selectedSeatIds: state.selectedSeatIds.filter(
            (seatId) => seatId !== action.seatId,
          ),
        };
      }
      if (state.selectedSeatIds.length >= MAX_SELECTED_SEATS) {
        return state;
      }
      return {
        ...state,
        selectedSeatIds: [...state.selectedSeatIds, action.seatId],
      };
    }
    case "clearBooking":
      return initialBookingState;
    default:
      return state;
  }
}

type BookingContextValue = {
  state: BookingState;
  dispatch: Dispatch<BookingAction>;
};

const BookingContext = createContext<BookingContextValue | null>(null);

export function BookingProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(bookingReducer, initialBookingState);
  return (
    <BookingContext.Provider value={{ state, dispatch }}>
      {children}
    </BookingContext.Provider>
  );
}

export function useBooking(): BookingContextValue {
  const context = useContext(BookingContext);
  if (!context) {
    throw new Error("useBooking must be used within a BookingProvider");
  }
  return context;
}
