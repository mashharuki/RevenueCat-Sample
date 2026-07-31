import { Tabs } from "expo-router/tabs";

import { FloatingTabBar } from "@/components/floating-tab-bar";

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{ headerShown: false }}
      tabBar={(props) => <FloatingTabBar {...props} />}
    >
      <Tabs.Screen name="index" options={{ title: "Home" }} />
      <Tabs.Screen name="tickets" options={{ title: "Tickets" }} />
    </Tabs>
  );
}
