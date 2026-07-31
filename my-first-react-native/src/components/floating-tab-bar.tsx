import { LinearGradient } from "expo-linear-gradient";
import type { BottomTabBarProps } from "expo-router/tabs";
import { Pressable, StyleSheet, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { ThemedText } from "@/components/themed-text";
import { MovieColors, Radius, Spacing } from "@/constants/theme";

const TAB_LABELS: Record<string, string> = {
  index: "Home",
  tickets: "Tickets",
};

export function FloatingTabBar({ state, navigation }: BottomTabBarProps) {
  const insets = useSafeAreaInsets();

  return (
    <View
      style={[styles.wrapper, { paddingBottom: insets.bottom + Spacing.two }]}
      pointerEvents="box-none"
    >
      <View style={styles.bar}>
        {state.routes.map((route, index) => {
          const isFocused = state.index === index;
          const label = TAB_LABELS[route.name] ?? route.name;

          function onPress() {
            const event = navigation.emit({
              type: "tabPress",
              target: route.key,
              canPreventDefault: true,
            });
            if (!isFocused && !event.defaultPrevented) {
              navigation.navigate(route.name);
            }
          }

          return (
            <Pressable key={route.key} onPress={onPress} style={styles.tabItem}>
              {isFocused ? (
                <LinearGradient
                  colors={MovieColors.primaryGradient}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 0 }}
                  style={styles.activePill}
                >
                  <ThemedText type="smallBold" style={styles.activeLabel}>
                    {label}
                  </ThemedText>
                </LinearGradient>
              ) : (
                <ThemedText type="small" themeColor="textSecondary">
                  {label}
                </ThemedText>
              )}
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    alignItems: "center",
  },
  bar: {
    flexDirection: "row",
    backgroundColor: MovieColors.surfaceElevated,
    borderRadius: Radius.pill,
    padding: Spacing.one,
    gap: Spacing.one,
  },
  tabItem: {
    minWidth: 96,
    alignItems: "center",
    justifyContent: "center",
  },
  activePill: {
    width: "100%",
    paddingVertical: Spacing.two,
    paddingHorizontal: Spacing.four,
    borderRadius: Radius.pill,
    alignItems: "center",
  },
  activeLabel: {
    color: MovieColors.text,
  },
});
