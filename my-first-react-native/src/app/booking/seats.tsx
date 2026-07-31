import { useRouter } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";

import { MovieColors, Spacing } from "@/constants/theme";

export default function SeatSelectionScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Seat Selection</Text>
      <Pressable onPress={() => router.push("/booking/checkout")}>
        <Text style={styles.link}>Go to Checkout →</Text>
      </Pressable>
      <Pressable onPress={() => router.back()}>
        <Text style={styles.link}>← Back</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: MovieColors.background,
    alignItems: "center",
    justifyContent: "center",
    gap: Spacing.three,
  },
  title: { color: MovieColors.text, fontSize: 20, fontWeight: "700" },
  link: { color: MovieColors.primary, fontSize: 16 },
});
