import { StyleSheet, Text, View } from "react-native";

import { MovieColors } from "@/constants/theme";

export default function TicketsScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>My Tickets</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: MovieColors.background,
    alignItems: "center",
    justifyContent: "center",
  },
  title: { color: MovieColors.text, fontSize: 20, fontWeight: "700" },
});
