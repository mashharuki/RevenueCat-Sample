class GameResult {
  final int score;
  final int wave;
  final bool isNewHigh;

  const GameResult({
    required this.score,
    required this.wave,
    this.isNewHigh = false,
  });

  @override
  bool operator ==(Object other) =>
      other is GameResult &&
      other.score == score &&
      other.wave == wave &&
      other.isNewHigh == isNewHigh;

  @override
  int get hashCode => Object.hash(score, wave, isNewHigh);
}
