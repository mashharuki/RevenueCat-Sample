import { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";

import { MovieColors, Spacing } from "@/constants/theme";

type BarcodeProps = {
  code: string;
};

function buildBarWidths(code: string): number[] {
  return code.split("").map((char) => (char.charCodeAt(0) % 3) + 1);
}

export function Barcode({ code }: BarcodeProps) {
  const bars = useMemo(() => buildBarWidths(code), [code]);

  return (
    <View style={styles.container}>
      <View style={styles.bars}>
        {bars.map((width, index) => (
          <View key={`${code}-${index}`} style={[styles.bar, { flex: width }]} />
        ))}
      </View>
      <Text style={styles.code}>{code}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: Spacing.two,
  },
  bars: {
    flexDirection: "row",
    height: 48,
    gap: 3,
  },
  bar: {
    backgroundColor: MovieColors.text,
    height: "100%",
  },
  code: {
    color: MovieColors.textSecondary,
    textAlign: "center",
    letterSpacing: 4,
    fontSize: 12,
    fontWeight: "600",
  },
});
