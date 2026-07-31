import { useRouter } from "expo-router";
import { useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import { GradientButton } from "@/components/ui/gradient-button";
import { ScreenState } from "@/components/ui/screen-state";
import { MovieColors, Radius, Spacing } from "@/constants/theme";
import { useBooking } from "@/context/booking-context";
import { useTickets } from "@/context/tickets-context";
import { useAsync } from "@/hooks/use-async";
import { fetchMovieById } from "@/services/movies";
import { calculateTotal } from "@/services/pricing";
import type { ServiceError } from "@/services/result";
import { fetchSeatMap, parseSeatId } from "@/services/seats";
import { fetchShowtimeById } from "@/services/showtimes";
import { formatDayLabel } from "@/utils/format-date";

export default function CheckoutScreen() {
  const router = useRouter();
  const { state, dispatch } = useBooking();
  const { purchase } = useTickets();

  const movieId = state.movieId ?? "";
  const showtimeId = state.showtimeId ?? "";

  const movieAsync = useAsync(() => fetchMovieById(movieId), [movieId]);
  const showtimeAsync = useAsync(
    () => fetchShowtimeById(showtimeId),
    [showtimeId],
  );
  const seatMapAsync = useAsync(() => fetchSeatMap(showtimeId), [showtimeId]);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [purchaseError, setPurchaseError] = useState<ServiceError | null>(null);

  const isLoading =
    movieAsync.isLoading || showtimeAsync.isLoading || seatMapAsync.isLoading;
  const loadError =
    movieAsync.error ?? showtimeAsync.error ?? seatMapAsync.error;

  const movie = movieAsync.data;
  const showtime = showtimeAsync.data;
  const seatMap = seatMapAsync.data;

  const seats = seatMap
    ? state.selectedSeatIds.map((seatId) =>
        parseSeatId(seatId, seatMap.vipRows),
      )
    : [];
  const totalUsd = showtime ? calculateTotal(seats, showtime.priceUsd) : 0;

  async function handlePay() {
    setIsSubmitting(true);
    setPurchaseError(null);
    const result = await purchase({
      movieId,
      showtimeId,
      seatIds: state.selectedSeatIds,
    });
    setIsSubmitting(false);

    if (result.ok) {
      dispatch({ type: "clearBooking" });
      router.dismissTo("/(tabs)/tickets");
    } else {
      setPurchaseError(result.error);
    }
  }

  function handleReload() {
    movieAsync.reload();
    showtimeAsync.reload();
    seatMapAsync.reload();
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScreenState
        isLoading={isLoading}
        error={loadError}
        onRetry={handleReload}
      >
        {movie && showtime && (
          <View style={styles.content}>
            <Text style={styles.heading}>Confirm your booking</Text>

            <View style={styles.card}>
              <Text style={styles.movieTitle}>{movie.title}</Text>
              <Text style={styles.detailText}>
                {formatDayLabel(showtime.date).day} • {showtime.time} •{" "}
                {showtime.hall}
              </Text>
              <Text style={styles.detailText}>
                Seats: {state.selectedSeatIds.join(", ")}
              </Text>
              <View style={styles.divider} />
              <View style={styles.row}>
                <Text style={styles.rowLabel}>Total</Text>
                <Text style={styles.rowValue}>${totalUsd.toFixed(2)}</Text>
              </View>
            </View>

            {purchaseError && (
              <View style={styles.errorBox}>
                <Text style={styles.errorText}>{purchaseError.message}</Text>
                <Text style={styles.errorLink} onPress={() => router.back()}>
                  Back to seat selection
                </Text>
              </View>
            )}

            <View style={styles.footer}>
              <GradientButton
                label={`Pay $${totalUsd.toFixed(2)}`}
                onPress={handlePay}
                loading={isSubmitting}
                disabled={state.selectedSeatIds.length === 0}
              />
            </View>
          </View>
        )}
      </ScreenState>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: MovieColors.background,
  },
  content: {
    flex: 1,
    padding: Spacing.four,
    justifyContent: "space-between",
  },
  heading: {
    color: MovieColors.text,
    fontSize: 22,
    fontWeight: "700",
    marginBottom: Spacing.four,
  },
  card: {
    backgroundColor: MovieColors.surface,
    borderRadius: Radius.lg,
    padding: Spacing.four,
    gap: Spacing.two,
  },
  movieTitle: {
    color: MovieColors.text,
    fontSize: 18,
    fontWeight: "700",
  },
  detailText: {
    color: MovieColors.textSecondary,
    fontSize: 14,
  },
  divider: {
    height: 1,
    backgroundColor: MovieColors.divider,
    marginVertical: Spacing.two,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  rowLabel: {
    color: MovieColors.textSecondary,
    fontSize: 16,
  },
  rowValue: {
    color: MovieColors.primary,
    fontSize: 20,
    fontWeight: "700",
  },
  errorBox: {
    marginTop: Spacing.four,
    padding: Spacing.three,
    borderRadius: Radius.md,
    backgroundColor: MovieColors.surfaceElevated,
    gap: Spacing.one,
  },
  errorText: {
    color: MovieColors.seatReserved,
    fontSize: 14,
  },
  errorLink: {
    color: MovieColors.text,
    fontWeight: "600",
  },
  footer: {
    marginTop: Spacing.four,
  },
});
