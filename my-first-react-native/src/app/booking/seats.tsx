import { useRouter } from "expo-router";
import { useMemo } from "react";
import { StyleSheet, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import { BookingSummaryBar } from "@/components/movie/booking-summary-bar";
import { ScreenCurve } from "@/components/movie/screen-curve";
import { SeatGrid } from "@/components/movie/seat-grid";
import { SeatLegend } from "@/components/movie/seat-legend";
import { ScreenState } from "@/components/ui/screen-state";
import { MovieColors, Spacing } from "@/constants/theme";
import { useBooking } from "@/context/booking-context";
import { useAsync } from "@/hooks/use-async";
import { calculateTotal } from "@/services/pricing";
import { fetchSeatMap, parseSeatId } from "@/services/seats";
import { fetchShowtimeById } from "@/services/showtimes";
import { formatDayLabel } from "@/utils/format-date";

export default function SeatSelectionScreen() {
  const router = useRouter();
  const { state, dispatch } = useBooking();
  const showtimeId = state.showtimeId ?? "";

  const seatMapAsync = useAsync(() => fetchSeatMap(showtimeId), [showtimeId]);
  const showtimeAsync = useAsync(
    () => fetchShowtimeById(showtimeId),
    [showtimeId],
  );

  const isLoading = seatMapAsync.isLoading || showtimeAsync.isLoading;
  const error = seatMapAsync.error ?? showtimeAsync.error;
  const seatMap = seatMapAsync.data;
  const showtime = showtimeAsync.data;

  const totalUsd = useMemo(() => {
    if (!seatMap || !showtime) return 0;
    const seats = state.selectedSeatIds.map((seatId) =>
      parseSeatId(seatId, seatMap.vipRows),
    );
    return calculateTotal(seats, showtime.priceUsd);
  }, [seatMap, showtime, state.selectedSeatIds]);

  function handleReload() {
    seatMapAsync.reload();
    showtimeAsync.reload();
  }

  function handleBuy() {
    router.push("/booking/checkout");
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScreenState isLoading={isLoading} error={error} onRetry={handleReload}>
        {seatMap && showtime && (
          <>
            <View style={styles.content}>
              <ScreenCurve />
              <SeatGrid
                seatMap={seatMap}
                selectedSeatIds={state.selectedSeatIds}
                onToggleSeat={(seatId) =>
                  dispatch({ type: "toggleSeat", seatId })
                }
              />
              <SeatLegend />
            </View>
            <View style={styles.footer}>
              <BookingSummaryBar
                dateLabel={formatDayLabel(showtime.date).day}
                timeLabel={showtime.time}
                seatLabels={state.selectedSeatIds}
                totalUsd={totalUsd}
                onPressBuy={handleBuy}
              />
            </View>
          </>
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
    paddingTop: Spacing.five,
    paddingHorizontal: Spacing.four,
  },
  footer: {
    padding: Spacing.four,
  },
});
