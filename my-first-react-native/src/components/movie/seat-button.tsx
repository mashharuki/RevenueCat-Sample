import { Pressable, StyleSheet } from "react-native";

import { MovieColors, Radius } from "@/constants/theme";
import type { SeatSection, SeatStatus } from "@/types/seat";

type SeatButtonProps = {
  status: SeatStatus;
  section: SeatSection;
  onPress: () => void;
};

function getSeatColor(status: SeatStatus, section: SeatSection): string {
  if (status === "reserved") return MovieColors.seatReserved;
  if (status === "selected") return MovieColors.seatSelected;
  return section === "vip"
    ? MovieColors.primaryDark
    : MovieColors.seatAvailable;
}

export function SeatButton({ status, section, onPress }: SeatButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      disabled={status === "reserved"}
      style={[styles.seat, { backgroundColor: getSeatColor(status, section) }]}
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
