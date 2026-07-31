import { StyleSheet, View } from "react-native";

import { SeatButton } from "./seat-button";
import { Spacing } from "@/constants/theme";
import type { SeatMap, SeatStatus } from "@/types/seat";

type SeatGridProps = {
  seatMap: SeatMap;
  selectedSeatIds: string[];
  onToggleSeat: (seatId: string) => void;
};

function getSeatStatus(seatId: string, seatMap: SeatMap, selectedSeatIds: string[]): SeatStatus {
  if (seatMap.reservedSeatIds.includes(seatId)) return "reserved";
  if (selectedSeatIds.includes(seatId)) return "selected";
  return "available";
}

export function SeatGrid({ seatMap, selectedSeatIds, onToggleSeat }: SeatGridProps) {
  const aisleAfterSeatNumber = seatMap.seatsPerRow / 2;

  return (
    <View style={styles.grid}>
      {seatMap.rows.map((row) => (
        <View key={row} style={styles.row}>
          {Array.from({ length: seatMap.seatsPerRow }, (_, index) => {
            const number = index + 1;
            const seatId = `${row}-${number}`;
            return (
              <View key={seatId} style={number === aisleAfterSeatNumber + 1 && styles.aisleGap}>
                <SeatButton
                  status={getSeatStatus(seatId, seatMap, selectedSeatIds)}
                  onPress={() => onToggleSeat(seatId)}
                />
              </View>
            );
          })}
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  grid: {
    gap: Spacing.two,
    alignItems: "center",
  },
  row: {
    flexDirection: "row",
    gap: Spacing.one,
  },
  aisleGap: {
    marginLeft: Spacing.three,
  },
});
