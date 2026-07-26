import CoreGraphics

struct BrickPlacement {
  let position: CGPoint
  let row: Int
}

enum BrickLayout {
  static let columns = 6
  static let rows = 5
  static let brickSize = CGSize(width: 48, height: 20)
  static let spacing: CGFloat = 4
  static let topMargin: CGFloat = 60

  static func standardLayout(in sceneSize: CGSize) -> [BrickPlacement] {
    layout(forLevel: 1, in: sceneSize)
  }

  /// Row count grows with the level so the premium-only levels (2-3) are
  /// genuinely harder content, not just a re-skin of level 1.
  static func rows(forLevel level: Int) -> Int {
    rows + (level - 1)
  }

  static func layout(forLevel level: Int, in sceneSize: CGSize) -> [BrickPlacement] {
    let rowCount = rows(forLevel: level)
    let totalWidth = CGFloat(columns) * brickSize.width + CGFloat(columns - 1) * spacing
    let startX = (sceneSize.width - totalWidth) / 2 + brickSize.width / 2
    let startY = sceneSize.height - topMargin

    var placements: [BrickPlacement] = []
    for row in 0 ..< rowCount {
      for column in 0 ..< columns {
        let x = startX + CGFloat(column) * (brickSize.width + spacing)
        let y = startY - CGFloat(row) * (brickSize.height + spacing)
        placements.append(BrickPlacement(position: CGPoint(x: x, y: y), row: row))
      }
    }
    return placements
  }
}
