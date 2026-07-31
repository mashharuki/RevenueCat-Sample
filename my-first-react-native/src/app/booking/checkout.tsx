import { useRouter } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";

import { MovieColors, Spacing } from "@/constants/theme";

export default function CheckoutScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Checkout</Text>
      <Pressable onPress={() => router.replace("/(tabs)/tickets")}>
        <Text style={styles.link}>Go to My Tickets →</Text>
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
