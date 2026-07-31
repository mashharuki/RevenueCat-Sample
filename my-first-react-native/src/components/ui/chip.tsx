import { Pressable, StyleSheet, Text } from "react-native";

import { MovieColors, Radius, Spacing } from "@/constants/theme";

type ChipProps = {
  label: string;
  selected?: boolean;
  onPress: () => void;
};

export function Chip({ label, selected = false, onPress }: ChipProps) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [styles.base, selected && styles.selected, pressed && styles.pressed]}
    >
      <Text style={[styles.label, selected && styles.labelSelected]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    paddingVertical: Spacing.two,
    paddingHorizontal: Spacing.three,
    borderRadius: Radius.pill,
    backgroundColor: MovieColors.surfaceElevated,
    alignItems: "center",
    justifyContent: "center",
  },
  selected: {
    backgroundColor: MovieColors.primary,
  },
  pressed: {
    opacity: 0.8,
  },
  label: {
    color: MovieColors.textSecondary,
    fontSize: 14,
    fontWeight: "600",
  },
  labelSelected: {
    color: MovieColors.text,
  },
});
