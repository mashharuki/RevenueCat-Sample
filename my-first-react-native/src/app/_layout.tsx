import { DarkTheme, Stack, ThemeProvider } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { useEffect } from "react";

import { BookingProvider } from "@/context/booking-context";
import { TicketsProvider } from "@/context/tickets-context";

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  useEffect(() => {
    SplashScreen.hideAsync();
  }, []);

  return (
    <ThemeProvider value={DarkTheme}>
      <BookingProvider>
        <TicketsProvider>
          <StatusBar style="light" />
          <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="(tabs)" />
            <Stack.Screen name="movie/[id]" />
            <Stack.Screen name="booking/seats" />
            <Stack.Screen name="booking/checkout" />
          </Stack>
        </TicketsProvider>
      </BookingProvider>
    </ThemeProvider>
  );
}
