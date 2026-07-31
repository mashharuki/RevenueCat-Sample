import { StyleSheet, Text, View } from "react-native";

import { MovieColors } from "@/constants/theme";

export default function PlaceholderScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Movie Ticket Booking App</Text>
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
  title: {
    color: MovieColors.text,
    fontSize: 20,
    fontWeight: "700",
  },
});
