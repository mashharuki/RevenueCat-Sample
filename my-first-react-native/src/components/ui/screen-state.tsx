import type { ReactNode } from "react";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";

import { MovieColors, Radius, Spacing } from "@/constants/theme";
import type { ServiceError } from "@/services/result";

type ScreenStateProps = {
  isLoading: boolean;
  error: ServiceError | null;
  isEmpty?: boolean;
  emptyMessage?: string;
  onRetry: () => void;
  children: ReactNode;
};

export function ScreenState({
  isLoading,
  error,
  isEmpty = false,
  emptyMessage = "Nothing here yet.",
  onRetry,
  children,
}: ScreenStateProps) {
  if (isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={MovieColors.text} size="large" />
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.center}>
        <Text style={styles.message}>{error.message}</Text>
        <Pressable onPress={onRetry} style={styles.retryButton}>
          <Text style={styles.retryLabel}>Retry</Text>
        </Pressable>
      </View>
    );
  }

  if (isEmpty) {
    return (
      <View style={styles.center}>
        <Text style={styles.message}>{emptyMessage}</Text>
      </View>
    );
  }

  return <>{children}</>;
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    gap: Spacing.three,
    paddingHorizontal: Spacing.four,
  },
  message: {
    color: MovieColors.textSecondary,
    fontSize: 14,
    textAlign: "center",
  },
  retryButton: {
    paddingVertical: Spacing.two,
    paddingHorizontal: Spacing.four,
    borderRadius: Radius.pill,
    backgroundColor: MovieColors.surfaceElevated,
  },
  retryLabel: {
    color: MovieColors.text,
    fontWeight: "600",
  },
});
