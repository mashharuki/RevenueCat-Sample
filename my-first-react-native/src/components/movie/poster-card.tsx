import { LinearGradient } from "expo-linear-gradient";
import { Pressable, StyleSheet, Text, View } from "react-native";

import { MovieColors, Radius, Spacing } from "@/constants/theme";
import type { Movie } from "@/types/movie";

type PosterCardProps = {
  movie: Movie;
  onPress: () => void;
  variant?: "large" | "small";
};

const POSTER_WIDTH = 160;
const POSTER_HEIGHT = 220;

export function PosterCard({ movie, onPress, variant = "large" }: PosterCardProps) {
  if (variant === "small") {
    return (
      <Pressable onPress={onPress} style={styles.smallContainer}>
        <LinearGradient
          colors={movie.posterGradient}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.smallPoster}
        />
        <View style={styles.smallInfo}>
          <Text style={styles.smallTitle} numberOfLines={1}>
            {movie.title}
          </Text>
          <Text style={styles.smallMeta} numberOfLines={1}>
            {movie.genres.join(" • ")}
          </Text>
          <Text style={styles.smallRating}>★ {movie.rating.toFixed(1)}</Text>
        </View>
      </Pressable>
    );
  }

  return (
    <Pressable onPress={onPress} style={styles.largeContainer}>
      <LinearGradient
        colors={movie.posterGradient}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.largePoster}
      >
        <Text style={styles.largeTitle} numberOfLines={2}>
          {movie.title}
        </Text>
        <Text style={styles.largeRating}>★ {movie.rating.toFixed(1)}</Text>
      </LinearGradient>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  largeContainer: {
    width: POSTER_WIDTH,
  },
  largePoster: {
    width: POSTER_WIDTH,
    height: POSTER_HEIGHT,
    borderRadius: Radius.lg,
    padding: Spacing.three,
    justifyContent: "flex-end",
  },
  largeTitle: {
    color: MovieColors.text,
    fontSize: 16,
    fontWeight: "700",
  },
  largeRating: {
    color: MovieColors.text,
    marginTop: Spacing.one,
    fontSize: 12,
    fontWeight: "600",
  },
  smallContainer: {
    flexDirection: "row",
    gap: Spacing.three,
    alignItems: "center",
  },
  smallPoster: {
    width: 72,
    height: 100,
    borderRadius: Radius.md,
  },
  smallInfo: {
    flex: 1,
    gap: Spacing.one,
  },
  smallTitle: {
    color: MovieColors.text,
    fontSize: 16,
    fontWeight: "700",
  },
  smallMeta: {
    color: MovieColors.textSecondary,
    fontSize: 13,
  },
  smallRating: {
    color: MovieColors.primary,
    fontSize: 13,
    fontWeight: "600",
  },
});
