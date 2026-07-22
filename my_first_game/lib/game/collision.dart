bool aabbIntersects({
  required double ax,
  required double ay,
  required double aw,
  required double ah,
  required double bx,
  required double by,
  required double bw,
  required double bh,
}) {
  return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
}
