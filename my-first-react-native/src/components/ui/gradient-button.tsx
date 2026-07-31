import { LinearGradient } from "expo-linear-gradient";
import { ActivityIndicator, Pressable, StyleSheet, Text } from "react-native";

import { MovieColors, Radius, Spacing } from "@/constants/theme";

type GradientButtonProps = {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  loading?: boolean;
};

export function GradientButton({ label, onPress, disabled = false, loading = false }: GradientButtonProps) {
  const isDisabled = disabled || loading;

  return (
    <Pressable
      onPress={onPress}
      disabled={isDisabled}
      style={({ pressed }) => [pressed && !isDisabled && styles.pressed]}
    >
      <LinearGradient
        colors={isDisabled ? [MovieColors.textMuted, MovieColors.textMuted] : MovieColors.primaryGradient}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 0 }}
        style={styles.container}
      >
        {loading ? (
          <ActivityIndicator color={MovieColors.text} />
        ) : (
          <Text style={styles.label}>{label}</Text>
        )}
      </LinearGradient>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    height: 56,
    borderRadius: Radius.pill,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: Spacing.five,
  },
  pressed: {
    opacity: 0.85,
  },
  label: {
    color: MovieColors.text,
    fontSize: 16,
    fontWeight: "700",
  },
});
