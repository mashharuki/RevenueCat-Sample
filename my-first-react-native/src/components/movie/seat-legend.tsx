import { StyleSheet, Text, View } from "react-native";

import { MovieColors, Spacing } from "@/constants/theme";

const LEGEND_ITEMS = [
  { label: "Available", color: MovieColors.seatAvailable },
  { label: "VIP", color: MovieColors.primaryDark },
  { label: "Reserved", color: MovieColors.seatReserved },
  { label: "Selected", color: MovieColors.seatSelected },
] as const;

export function SeatLegend() {
  return (
    <View style={styles.row}>
      {LEGEND_ITEMS.map((item) => (
        <View key={item.label} style={styles.item}>
          <View style={[styles.dot, { backgroundColor: item.color }]} />
          <Text style={styles.label}>{item.label}</Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "center",
    gap: Spacing.three,
    marginVertical: Spacing.four,
  },
  item: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.one,
  },
  dot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  label: {
    color: MovieColors.textSecondary,
    fontSize: 12,
  },
});
