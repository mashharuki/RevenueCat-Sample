import { useMemo } from "react";
import { ScrollView, StyleSheet, Text } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import { TicketCard } from "@/components/movie/ticket-card";
import { ScreenState } from "@/components/ui/screen-state";
import { BottomTabInset, MovieColors, Spacing } from "@/constants/theme";
import { useTickets } from "@/context/tickets-context";
import { useAsync } from "@/hooks/use-async";
import { fetchMovies } from "@/services/movies";
import type { Movie } from "@/types/movie";

export default function TicketsScreen() {
  const { tickets, isLoading, error, reload } = useTickets();
  const moviesAsync = useAsync(fetchMovies, []);

  const movieById = useMemo(() => {
    const map = new Map<string, Movie>();
    for (const movie of moviesAsync.data ?? []) {
      map.set(movie.id, movie);
    }
    return map;
  }, [moviesAsync.data]);

  const combinedLoading = isLoading || moviesAsync.isLoading;
  const combinedError = error ?? moviesAsync.error;

  function handleReload() {
    reload();
    moviesAsync.reload();
  }

  return (
    <SafeAreaView style={styles.safeArea} edges={["top"]}>
      <Text style={styles.header}>My Tickets</Text>
      <ScreenState
        isLoading={combinedLoading}
        error={combinedError}
        isEmpty={!combinedLoading && !combinedError && tickets.length === 0}
        emptyMessage="Once you buy a movie ticket, it will show up here with a scannable barcode."
        onRetry={handleReload}
      >
        <ScrollView
          contentContainerStyle={styles.list}
          showsVerticalScrollIndicator={false}
        >
          {tickets.map((ticket) => {
            const movie = movieById.get(ticket.movieId);
            return movie ? (
              <TicketCard key={ticket.id} ticket={ticket} movie={movie} />
            ) : null;
          })}
        </ScrollView>
      </ScreenState>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: MovieColors.background,
  },
  header: {
    color: MovieColors.text,
    fontSize: 24,
    fontWeight: "700",
    paddingHorizontal: Spacing.four,
    paddingBottom: Spacing.three,
  },
  list: {
    gap: Spacing.four,
    paddingHorizontal: Spacing.four,
    paddingBottom: BottomTabInset + Spacing.five,
  },
});
