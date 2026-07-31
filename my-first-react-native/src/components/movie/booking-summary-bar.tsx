import { Pressable, StyleSheet, Text, View } from "react-native";

import { MovieColors, Radius, Spacing } from "@/constants/theme";

type BookingSummaryBarProps = {
  dateLabel: string;
  timeLabel: string;
  seatLabels: string[];
  totalUsd: number;
  onPressBuy: () => void;
};

export function BookingSummaryBar({ dateLabel, timeLabel, seatLabels, totalUsd, onPressBuy }: BookingSummaryBarProps) {
  return (
    <View style={styles.container}>
      <View style={styles.info}>
        <Text style={styles.dateTime}>
          {dateLabel} • {timeLabel}
        </Text>
        <Text style={styles.seats} numberOfLines={1}>
          {seatLabels.length > 0 ? `Seats: ${seatLabels.join(", ")}` : "Select your seats"}
        </Text>
        <Text style={styles.total}>${totalUsd.toFixed(2)}</Text>
      </View>
      <Pressable
        onPress={onPressBuy}
        disabled={seatLabels.length === 0}
        style={[styles.buyButton, seatLabels.length === 0 && styles.buyButtonDisabled]}
      >
        <Text style={styles.buyLabel}>Buy</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    backgroundColor: MovieColors.surface,
    borderRadius: Radius.xl,
    padding: Spacing.four,
    gap: Spacing.three,
  },
  info: {
    flex: 1,
    gap: Spacing.half,
  },
  dateTime: {
    color: MovieColors.textSecondary,
    fontSize: 12,
  },
  seats: {
    color: MovieColors.text,
    fontSize: 13,
    fontWeight: "600",
  },
  total: {
    color: MovieColors.primary,
    fontSize: 18,
    fontWeight: "700",
  },
  buyButton: {
    width: 64,
    height: 64,
    borderRadius: Radius.pill,
    backgroundColor: MovieColors.primary,
    alignItems: "center",
    justifyContent: "center",
  },
  buyButtonDisabled: {
    backgroundColor: MovieColors.textMuted,
  },
  buyLabel: {
    color: MovieColors.text,
    fontWeight: "700",
  },
});
