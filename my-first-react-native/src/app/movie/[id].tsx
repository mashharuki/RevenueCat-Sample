import { LinearGradient } from "expo-linear-gradient";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import { Chip } from "@/components/ui/chip";
import { GradientButton } from "@/components/ui/gradient-button";
import { ScreenState } from "@/components/ui/screen-state";
import { MovieColors, Radius, Spacing } from "@/constants/theme";
import { useBooking } from "@/context/booking-context";
import { useAsync } from "@/hooks/use-async";
import { fetchMovieById } from "@/services/movies";
import { fetchShowtimes } from "@/services/showtimes";
import { formatDayLabel } from "@/utils/format-date";

export default function MovieDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { dispatch } = useBooking();

  const movieAsync = useAsync(() => fetchMovieById(id), [id]);
  const showtimesAsync = useAsync(() => fetchShowtimes(id), [id]);

  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const [selectedShowtimeId, setSelectedShowtimeId] = useState<string | null>(null);

  const uniqueDates = useMemo(() => {
    const dates = (showtimesAsync.data ?? []).map((showtime) => showtime.date);
    return Array.from(new Set(dates)).sort();
  }, [showtimesAsync.data]);

  const activeDate = selectedDate ?? uniqueDates[0] ?? null;

  const timesForActiveDate = useMemo(
    () => (showtimesAsync.data ?? []).filter((showtime) => showtime.date === activeDate),
    [showtimesAsync.data, activeDate],
  );

  const isLoading = movieAsync.isLoading || showtimesAsync.isLoading;
  const error = movieAsync.error ?? showtimesAsync.error;
  const movie = movieAsync.data;

  function handleReload() {
    movieAsync.reload();
    showtimesAsync.reload();
  }

  function handleReservation() {
    if (!movie || !selectedShowtimeId) return;
    dispatch({ type: "selectShowtime", movieId: movie.id, showtimeId: selectedShowtimeId });
    router.push("/booking/seats");
  }

  return (
    <View style={styles.container}>
      <ScreenState isLoading={isLoading} error={error} onRetry={handleReload}>
        {movie && (
          <>
            <ScrollView contentContainerStyle={styles.scrollContent}>
              <LinearGradient
                colors={movie.posterGradient}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.poster}
              >
                <SafeAreaView edges={["top"]}>
                  <Pressable onPress={() => router.back()} style={styles.backButton}>
                    <Text style={styles.backLabel}>‹</Text>
                  </Pressable>
                </SafeAreaView>
                <Text style={styles.posterTitle}>{movie.title}</Text>
              </LinearGradient>

              <View style={styles.body}>
                <Text style={styles.tagline}>{movie.tagline}</Text>

                <View style={styles.metaRow}>
                  <Text style={styles.metaText}>{movie.durationMinutes} min</Text>
                  <Text style={styles.metaDot}>•</Text>
                  <Text style={styles.metaText}>{movie.ageRating}</Text>
                  <Text style={styles.metaDot}>•</Text>
                  <Text style={styles.metaText}>★ {movie.rating.toFixed(1)}</Text>
                </View>

                <Text style={styles.genres}>{movie.genres.join(" • ")}</Text>
                <Text style={styles.synopsis}>{movie.synopsis}</Text>

                <Text style={styles.sectionTitle}>Select date and time</Text>

                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chipRow}>
                  {uniqueDates.map((date) => (
                    <Chip
                      key={date}
                      label={formatDayLabel(date).day}
                      selected={date === activeDate}
                      onPress={() => {
                        setSelectedDate(date);
                        setSelectedShowtimeId(null);
                      }}
                    />
                  ))}
                </ScrollView>

                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chipRow}>
                  {timesForActiveDate.map((showtime) => (
                    <Chip
                      key={showtime.id}
                      label={showtime.time}
                      selected={showtime.id === selectedShowtimeId}
                      onPress={() => setSelectedShowtimeId(showtime.id)}
                    />
                  ))}
                </ScrollView>
              </View>
            </ScrollView>

            <View style={styles.footer}>
              <GradientButton label="Reservation" disabled={!selectedShowtimeId} onPress={handleReservation} />
            </View>
          </>
        )}
      </ScreenState>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: MovieColors.background,
  },
  scrollContent: {
    paddingBottom: Spacing.six,
  },
  poster: {
    height: 320,
    justifyContent: "flex-end",
    padding: Spacing.four,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: Radius.pill,
    backgroundColor: "rgba(15, 11, 30, 0.4)",
    alignItems: "center",
    justifyContent: "center",
  },
  backLabel: {
    color: MovieColors.text,
    fontSize: 24,
    lineHeight: 24,
  },
  posterTitle: {
    color: MovieColors.text,
    fontSize: 32,
    fontWeight: "700",
    marginTop: Spacing.five,
  },
  body: {
    padding: Spacing.four,
    gap: Spacing.two,
  },
  tagline: {
    color: MovieColors.textSecondary,
    fontStyle: "italic",
  },
  metaRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.two,
    marginTop: Spacing.two,
  },
  metaText: {
    color: MovieColors.text,
    fontSize: 13,
    fontWeight: "600",
  },
  metaDot: {
    color: MovieColors.textMuted,
  },
  genres: {
    color: MovieColors.primary,
    fontSize: 13,
    fontWeight: "600",
  },
  synopsis: {
    color: MovieColors.textSecondary,
    lineHeight: 20,
    marginTop: Spacing.two,
  },
  sectionTitle: {
    color: MovieColors.text,
    fontSize: 16,
    fontWeight: "700",
    marginTop: Spacing.four,
    marginBottom: Spacing.two,
  },
  chipRow: {
    gap: Spacing.two,
    paddingBottom: Spacing.three,
  },
  footer: {
    padding: Spacing.four,
    backgroundColor: MovieColors.background,
  },
});
