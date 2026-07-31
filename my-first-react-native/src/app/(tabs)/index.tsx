import { useRouter } from "expo-router";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import { PosterCard } from "@/components/movie/poster-card";
import { ScreenState } from "@/components/ui/screen-state";
import { MovieColors, Spacing } from "@/constants/theme";
import { useAsync } from "@/hooks/use-async";
import { fetchMovies } from "@/services/movies";

export default function HomeScreen() {
  const router = useRouter();
  const { data: movies, error, isLoading, reload } = useAsync(fetchMovies, []);

  const nowShowing = movies?.slice(0, 5) ?? [];
  const comingSoon = movies?.slice(5) ?? [];

  return (
    <SafeAreaView style={styles.safeArea} edges={["top"]}>
      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <Text style={styles.greeting}>Good evening</Text>
          <Text style={styles.title}>What are you watching tonight?</Text>
        </View>

        <ScreenState
          isLoading={isLoading}
          error={error}
          isEmpty={!isLoading && !error && (movies?.length ?? 0) === 0}
          emptyMessage="No movies are showing right now."
          onRetry={reload}
        >
          <Text style={styles.sectionTitle}>Now Showing</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.carousel}>
            {nowShowing.map((movie) => (
              <PosterCard
                key={movie.id}
                movie={movie}
                variant="large"
                onPress={() => router.push(`/movie/${movie.id}`)}
              />
            ))}
          </ScrollView>

          {comingSoon.length > 0 && (
            <View style={styles.comingSoonSection}>
              <Text style={styles.sectionTitle}>Coming Soon</Text>
              <View style={styles.comingSoonList}>
                {comingSoon.map((movie) => (
                  <PosterCard
                    key={movie.id}
                    movie={movie}
                    variant="small"
                    onPress={() => router.push(`/movie/${movie.id}`)}
                  />
                ))}
              </View>
            </View>
          )}
        </ScreenState>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: MovieColors.background,
  },
  content: {
    paddingBottom: 140,
  },
  header: {
    paddingHorizontal: Spacing.four,
    paddingTop: Spacing.three,
    paddingBottom: Spacing.four,
    gap: Spacing.one,
  },
  greeting: {
    color: MovieColors.textSecondary,
    fontSize: 14,
    fontWeight: "600",
  },
  title: {
    color: MovieColors.text,
    fontSize: 24,
    fontWeight: "700",
  },
  sectionTitle: {
    color: MovieColors.text,
    fontSize: 18,
    fontWeight: "700",
    paddingHorizontal: Spacing.four,
    marginBottom: Spacing.three,
  },
  carousel: {
    gap: Spacing.three,
    paddingHorizontal: Spacing.four,
  },
  comingSoonSection: {
    marginTop: Spacing.five,
  },
  comingSoonList: {
    gap: Spacing.four,
    paddingHorizontal: Spacing.four,
  },
});
