# Movie Ticket Booking App (practice project)

This is a learning/practice project built with [Expo](https://expo.dev) and React Native. It simulates an end-to-end movie ticket booking flow — browsing movies, picking a showtime, choosing seats, checking out, and viewing purchased tickets — entirely against a **mock in-memory backend**. There is no real payment processing and no real server: all data (movies, showtimes, seat maps, tickets) is generated and stored in-memory for the lifetime of the app session.

## Screens

The app implements a 5-screen booking flow using [Expo Router](https://docs.expo.dev/router/introduction) file-based routing:

1. **Home** (`src/app/(tabs)/index.tsx`) — Browse the list of now-showing movies.
2. **Movie Detail** (`src/app/movie/[id].tsx`) — View movie info and pick a date/showtime.
3. **Seat Selection** (`src/app/booking/seats.tsx`) — Pick one or more seats from the seat map for the selected showtime.
4. **Checkout** (`src/app/booking/checkout.tsx`) — Review the order summary and total, then "pay" (mock, no real charge).
5. **My Tickets** (`src/app/(tabs)/tickets.tsx`) — See previously purchased tickets, each rendered as a ticket card with a barcode.

The app uses a dark theme throughout.

## Getting started

Install dependencies:

```bash
bun install
```

Run the app in the iOS Simulator:

```bash
bun run ios
```

(`bun run android` and `bun run web` are also available for the other platforms.)

## Running tests

The mock backend logic (pricing, seat generation, ticket purchasing, and booking state) is covered by unit tests. Run the full suite with:

```bash
bun run test
```

## Quality checks

```bash
bunx tsc --noEmit   # type check
bunx biome check .  # lint + format check
```

## Manually testing error states

`src/services/mock-config.ts` exposes two flags for manually exercising UI states that are otherwise hard to trigger:

- `simulateNetworkErrors` — when `true`, mock service calls randomly fail so you can verify the app's network-error UI (retry states, error messages).
- `alwaysFailPurchase` — when `true`, the checkout "Pay" action always fails so you can verify the purchase-failure UI.

Both default to `false`. Flip either to `true` temporarily during development to check the corresponding UI path, then make sure to set it back to `false` before committing.
