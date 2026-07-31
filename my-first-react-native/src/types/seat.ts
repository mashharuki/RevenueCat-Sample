export type SeatSection = "standard" | "vip";
export type SeatStatus = "available" | "reserved" | "selected";

export type Seat = {
  id: string;
  row: string;
  number: number;
  section: SeatSection;
};

export type SeatMap = {
  showtimeId: string;
  rows: string[];
  seatsPerRow: number;
  vipRows: string[];
  reservedSeatIds: string[];
};
