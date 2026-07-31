import { LinearGradient } from "expo-linear-gradient";
import { StyleSheet, Text, View } from "react-native";

import { MovieColors, Spacing } from "@/constants/theme";

export function ScreenCurve() {
  return (
    <View style={styles.wrapper}>
      <LinearGradient
        colors={MovieColors.primaryGradient}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 0 }}
        style={styles.curve}
      />
      <Text style={styles.label}>SCREEN</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    alignItems: "center",
    marginBottom: Spacing.four,
  },
  curve: {
    width: "80%",
    height: 6,
    borderTopLeftRadius: 200,
    borderTopRightRadius: 200,
    opacity: 0.9,
  },
  label: {
    color: MovieColors.textMuted,
    fontSize: 11,
    letterSpacing: 4,
    marginTop: Spacing.two,
  },
});
