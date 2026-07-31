import { Pressable, StyleSheet } from "react-native";

import { MovieColors, Radius } from "@/constants/theme";
import type { SeatStatus } from "@/types/seat";

type SeatButtonProps = {
  status: SeatStatus;
  onPress: () => void;
};

const SEAT_COLOR: Record<SeatStatus, string> = {
  available: MovieColors.seatAvailable,
  reserved: MovieColors.seatReserved,
  selected: MovieColors.seatSelected,
};

export function SeatButton({ status, onPress }: SeatButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      disabled={status === "reserved"}
      style={[styles.seat, { backgroundColor: SEAT_COLOR[status] }]}
    />
  );
}

const styles = StyleSheet.create({
  seat: {
    width: 20,
    height: 20,
    borderRadius: Radius.sm,
  },
});
