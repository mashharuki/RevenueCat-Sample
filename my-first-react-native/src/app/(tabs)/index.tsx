import { useRouter } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";

import { MovieColors, Spacing } from "@/constants/theme";

export default function HomeScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Home</Text>
      <Pressable onPress={() => router.push("/movie/nebula-drift")}>
        <Text style={styles.link}>Go to Movie Detail →</Text>
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
