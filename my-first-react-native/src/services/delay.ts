const MIN_DELAY_MS = 300;
const MAX_DELAY_MS = 600;

export function delay(): Promise<void> {
  const durationMs = MIN_DELAY_MS + Math.random() * (MAX_DELAY_MS - MIN_DELAY_MS);
  return new Promise((resolve) => setTimeout(resolve, durationMs));
}
