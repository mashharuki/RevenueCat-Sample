import 'dart:ui';

class PixelSprite {
  final List<String> rows;

  const PixelSprite(this.rows);

  int get columns => rows.isEmpty ? 0 : rows.first.length;

  int get rowCount => rows.length;

  List<Offset> filledCells() {
    final cells = <Offset>[];
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        if (rows[r][c] == '1') {
          cells.add(Offset(c.toDouble(), r.toDouble()));
        }
      }
    }
    return cells;
  }
}

class InvaderSprites {
  static const enemyAlpha = PixelSprite([
    '00111100',
    '01111110',
    '11011011',
    '11111111',
    '00100100',
    '01011010',
    '10100101',
    '01000010',
  ]);

  static const enemyBeta = PixelSprite([
    '01000010',
    '00100100',
    '01111110',
    '11011011',
    '11111111',
    '10111101',
    '10100101',
    '00100100',
  ]);

  static const enemyGamma = PixelSprite([
    '00011000',
    '00111100',
    '01111110',
    '11011011',
    '11111111',
    '00100100',
    '01011010',
    '10100101',
  ]);

  static const player = PixelSprite([
    '000000110000',
    '000001111000',
    '000001111000',
    '011111111110',
    '111111111111',
    '111111111111',
    '101111111101',
    '100100000101',
  ]);

  static const boss = PixelSprite([
    '00000111111000000',
    '00011111111110000',
    '00111111111111000',
    '01100111111001100',
    '11111111111111111',
    '11011111111110110',
    '11001111111100110',
    '00111000001110000',
    '00011000000110000',
    '00001100001100000',
  ]);
}
