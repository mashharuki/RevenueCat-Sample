export function formatDayLabel(iso: string): { weekday: string; day: string } {
  const date = new Date(`${iso}T00:00:00`);
  const weekday = date.toLocaleDateString("en-US", { weekday: "short" });
  const dayNumber = date.toLocaleDateString("en-US", { day: "numeric" });
  return { weekday, day: `${weekday} ${dayNumber}` };
}
