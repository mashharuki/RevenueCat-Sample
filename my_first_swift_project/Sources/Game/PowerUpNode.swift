import SpriteKit

final class PowerUpNode: SKSpriteNode {
  let type: PowerUpType

  init(type: PowerUpType, size: CGSize, color: SKColor) {
    self.type = type
    super.init(texture: nil, color: color, size: size)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
