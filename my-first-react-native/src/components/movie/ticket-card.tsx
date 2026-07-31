import { LinearGradient } from "expo-linear-gradient";
import { StyleSheet, Text, View } from "react-native";

import { Barcode } from "@/components/ui/barcode";
import { MovieColors, Radius, Spacing } from "@/constants/theme";
import type { Movie } from "@/types/movie";
import type { Ticket } from "@/types/ticket";
import { formatDayLabel } from "@/utils/format-date";

type TicketCardProps = {
  ticket: Ticket;
  movie: Movie;
};

export function TicketCard({ ticket, movie }: TicketCardProps) {
  return (
    <View style={styles.container}>
      <LinearGradient
        colors={movie.posterGradient}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.top}
      >
        <Text style={styles.movieTitle}>{movie.title}</Text>
        <Text style={styles.movieMeta}>{movie.genres.join(" • ")}</Text>
      </LinearGradient>

      <View style={styles.perforationRow}>
        <View style={styles.notch} />
        <View style={styles.dashedLine} />
        <View style={styles.notch} />
      </View>

      <View style={styles.bottom}>
        <View style={styles.detailsGrid}>
          <View style={styles.detailItem}>
            <Text style={styles.detailLabel}>Date</Text>
            <Text style={styles.detailValue}>{formatDayLabel(ticket.purchasedAt.slice(0, 10)).day}</Text>
          </View>
          <View style={styles.detailItem}>
            <Text style={styles.detailLabel}>Seats</Text>
            <Text style={styles.detailValue}>{ticket.seatIds.join(", ")}</Text>
          </View>
          <View style={styles.detailItem}>
            <Text style={styles.detailLabel}>Total</Text>
            <Text style={styles.detailValue}>${ticket.totalUsd.toFixed(2)}</Text>
          </View>
        </View>
        <Barcode code={ticket.bookingCode} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: Radius.xl,
    backgroundColor: MovieColors.surface,
    overflow: "hidden",
  },
  top: {
    padding: Spacing.four,
    height: 120,
    justifyContent: "flex-end",
  },
  movieTitle: {
    color: MovieColors.text,
    fontSize: 18,
    fontWeight: "700",
  },
  movieMeta: {
    color: MovieColors.text,
    fontSize: 12,
    opacity: 0.85,
  },
  perforationRow: {
    flexDirection: "row",
    alignItems: "center",
  },
  notch: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: MovieColors.background,
  },
  dashedLine: {
    flex: 1,
    height: 1,
    borderStyle: "dashed",
    borderWidth: 1,
    borderColor: MovieColors.divider,
    marginHorizontal: Spacing.one,
  },
  bottom: {
    padding: Spacing.four,
    gap: Spacing.four,
  },
  detailsGrid: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  detailItem: {
    gap: Spacing.half,
  },
  detailLabel: {
    color: MovieColors.textMuted,
    fontSize: 11,
    textTransform: "uppercase",
  },
  detailValue: {
    color: MovieColors.text,
    fontSize: 14,
    fontWeight: "600",
  },
});
