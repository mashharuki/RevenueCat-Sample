import { useState } from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

import { Barcode } from "@/components/ui/barcode";
import { Chip } from "@/components/ui/chip";
import { GradientButton } from "@/components/ui/gradient-button";
import { MovieColors, Spacing } from "@/constants/theme";

export default function HomeScreen() {
  const [selected, setSelected] = useState("Mon 25");

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.title}>Component Showcase</Text>

      <View style={styles.row}>
        {["Sat 23", "Sun 24", "Mon 25"].map((label) => (
          <Chip key={label} label={label} selected={selected === label} onPress={() => setSelected(label)} />
        ))}
      </View>

      <GradientButton label="Reservation" onPress={() => {}} />
      <GradientButton label="Disabled" onPress={() => {}} disabled />

      <Barcode code="AB12CD34" />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: MovieColors.background,
  },
  content: {
    padding: Spacing.four,
    gap: Spacing.four,
  },
  title: {
    color: MovieColors.text,
    fontSize: 20,
    fontWeight: "700",
  },
  row: {
    flexDirection: "row",
    gap: Spacing.two,
  },
});
