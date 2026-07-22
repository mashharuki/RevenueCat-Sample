import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private static let paddleSize = CGSize(width: 100, height: 20)
    private static let paddleBottomMargin: CGFloat = 80
    private static let ballRadius: CGFloat = 8
    private static let launchSpeed: CGFloat = 300
    private static let minBallSpeed: CGFloat = 280
    private static let maxBallSpeed: CGFloat = 500
    private static let paddleInfluenceFactor: CGFloat = 200
    private static let relaunchDelay: TimeInterval = 0.5
    private static let brickFadeDuration: TimeInterval = 0.15
    private static let multiBallSpreadDegrees: [CGFloat] = [-20, 20]

    private static let powerUpDropChance: Double = 0.2
    private static let powerUpCapsuleSize = CGSize(width: 30, height: 14)
    private static let powerUpFallSpeed: CGFloat = -120
    private static let paddleGrowDuration: TimeInterval = 10
    private static let paddleGrowWidthMultiplier: CGFloat = 1.5
    private static let laserDuration: TimeInterval = 8
    private static let laserFireInterval: TimeInterval = 0.4
    private static let laserBoltSpeed: CGFloat = 400
    private static let laserBoltSize = CGSize(width: 4, height: 16)

    private let viewModel: GameViewModel
    private let paddle = SKSpriteNode(color: .white, size: GameScene.paddleSize)
    private let bricksNode = SKNode()
    private var balls: [SKShapeNode] = []
    private var activePowerUps: [PowerUpNode] = []
    private var activeLaserBolts: [SKSpriteNode] = []
    private var isWaitingForLaunch = true
    private var currentGameTime: TimeInterval = 0
    private var paddleGrowExpiryTime: TimeInterval?
    private var laserExpiryTime: TimeInterval?
    private var lastLaserFireTime: TimeInterval = 0

    init(size: CGSize, viewModel: GameViewModel) {
        self.viewModel = viewModel
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setUpWalls()
        setUpPaddle()
        addChild(bricksNode)
        resetToSingleBall()
    }

    private func setUpWalls() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: size.width, y: 0))

        let wallBody = SKPhysicsBody(edgeChainFrom: path)
        wallBody.categoryBitMask = PhysicsCategory.wall
        wallBody.friction = 0
        physicsBody = wallBody
    }

    private func setUpPaddle() {
        paddle.position = CGPoint(x: size.width / 2, y: GameScene.paddleBottomMargin)
        resizePaddle(toWidth: GameScene.paddleSize.width)
        addChild(paddle)
    }

    private func resizePaddle(toWidth width: CGFloat) {
        paddle.size = CGSize(width: width, height: GameScene.paddleSize.height)
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.isDynamic = false
        paddle.physicsBody?.categoryBitMask = PhysicsCategory.paddle
        paddle.physicsBody?.contactTestBitMask = PhysicsCategory.ball
    }

    private func makeBall() -> SKShapeNode {
        let ball = SKShapeNode(circleOfRadius: GameScene.ballRadius)
        ball.fillColor = .white
        ball.strokeColor = .clear
        ball.physicsBody = SKPhysicsBody(circleOfRadius: GameScene.ballRadius)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.friction = 0
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.paddle | PhysicsCategory.brick | PhysicsCategory.wall
        ball.physicsBody?.collisionBitMask = PhysicsCategory.paddle | PhysicsCategory.brick | PhysicsCategory.wall
        return ball
    }

    // MARK: - Game lifecycle

    func startGame() {
        resetPowerUpState()
        buildBricks()
        resetToSingleBall()
        launchBall()
    }

    func resetGame() {
        startGame()
    }

    private func resetPowerUpState() {
        activePowerUps.forEach { $0.removeFromParent() }
        activePowerUps.removeAll()
        activeLaserBolts.forEach { $0.removeFromParent() }
        activeLaserBolts.removeAll()
        resizePaddle(toWidth: GameScene.paddleSize.width)
        paddleGrowExpiryTime = nil
        laserExpiryTime = nil
        viewModel.resetPowerUps()
    }

    private func buildBricks() {
        removeAllBricks()
        let placements = BrickLayout.standardLayout(in: size)
        for placement in placements {
            let brick = makeBrickNode(at: placement)
            bricksNode.addChild(brick)
        }
    }

    private func makeBrickNode(at placement: BrickPlacement) -> SKSpriteNode {
        let brick = SKSpriteNode(color: brickColor(forRow: placement.row), size: BrickLayout.brickSize)
        brick.position = placement.position
        brick.physicsBody = SKPhysicsBody(rectangleOf: BrickLayout.brickSize)
        brick.physicsBody?.isDynamic = false
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        brick.physicsBody?.collisionBitMask = PhysicsCategory.ball
        brick.physicsBody?.contactTestBitMask = PhysicsCategory.none
        return brick
    }

    private func brickColor(forRow row: Int) -> SKColor {
        let colors: [SKColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemBlue]
        return colors[row % colors.count]
    }

    private func removeAllBricks() {
        bricksNode.removeAllChildren()
    }

    private func resetToSingleBall() {
        balls.forEach { $0.removeFromParent() }
        balls.removeAll()
        let newBall = makeBall()
        newBall.position = CGPoint(x: paddle.position.x, y: paddle.position.y + paddle.size.height)
        addChild(newBall)
        balls.append(newBall)
        isWaitingForLaunch = true
    }

    private func launchBall() {
        guard isWaitingForLaunch, let ball = balls.first else { return }
        isWaitingForLaunch = false
        let randomDx = CGFloat.random(in: -60...60)
        ball.physicsBody?.velocity = CGVector(dx: randomDx, dy: GameScene.launchSpeed)
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        movePaddle(with: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        movePaddle(with: touches)
    }

    private func movePaddle(with touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let touchX = touch.location(in: self).x
        let halfWidth = paddle.size.width / 2
        let clampedX = GameMath.clamp(touchX, min: halfWidth, max: size.width - halfWidth)
        paddle.position.x = clampedX
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        currentGameTime = currentTime
        clampBallSpeeds()
        checkBallsFellBelowPaddle()
        updatePaddleGrowExpiry()
        updateLaserFiring()
        cleanUpOffscreenPowerUps()
        cleanUpOffscreenLaserBolts()
    }

    private func clampBallSpeeds() {
        guard !isWaitingForLaunch else { return }
        for ball in balls {
            guard let velocity = ball.physicsBody?.velocity else { continue }
            let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            guard speed > 0 else { continue }
            let clampedSpeed = GameMath.clamp(speed, min: GameScene.minBallSpeed, max: GameScene.maxBallSpeed)
            guard clampedSpeed != speed else { continue }
            let scale = clampedSpeed / speed
            ball.physicsBody?.velocity = CGVector(dx: velocity.dx * scale, dy: velocity.dy * scale)
        }
    }

    private func checkBallsFellBelowPaddle() {
        guard !isWaitingForLaunch else { return }
        let fallenBalls = balls.filter { $0.position.y < 0 }
        guard !fallenBalls.isEmpty else { return }
        fallenBalls.forEach { $0.removeFromParent() }
        balls.removeAll { ball in fallenBalls.contains { $0 === ball } }
        guard balls.isEmpty else { return }
        handleBallLost()
    }

    private func handleBallLost() {
        resetToSingleBall()
        let hasLivesRemaining = viewModel.loseLife()
        guard hasLivesRemaining else { return }
        let relaunch = SKAction.sequence([
            .wait(forDuration: GameScene.relaunchDelay),
            .run { [weak self] in self?.launchBall() }
        ])
        run(relaunch)
    }

    // MARK: - Power-ups

    private func maybeDropPowerUp(from position: CGPoint) {
        guard Double.random(in: 0...1) < GameScene.powerUpDropChance, let type = PowerUpType.allCases.randomElement() else { return }
        let capsule = makePowerUpCapsule(type: type, at: position)
        addChild(capsule)
        activePowerUps.append(capsule)
    }

    private func makePowerUpCapsule(type: PowerUpType, at position: CGPoint) -> PowerUpNode {
        let capsule = PowerUpNode(type: type, size: GameScene.powerUpCapsuleSize, color: color(for: type))
        capsule.position = position
        capsule.physicsBody = SKPhysicsBody(rectangleOf: GameScene.powerUpCapsuleSize)
        capsule.physicsBody?.isDynamic = true
        capsule.physicsBody?.affectedByGravity = false
        capsule.physicsBody?.categoryBitMask = PhysicsCategory.powerUp
        capsule.physicsBody?.contactTestBitMask = PhysicsCategory.paddle
        capsule.physicsBody?.collisionBitMask = PhysicsCategory.none
        capsule.physicsBody?.velocity = CGVector(dx: 0, dy: GameScene.powerUpFallSpeed)
        return capsule
    }

    private func color(for type: PowerUpType) -> SKColor {
        switch type {
        case .multiBall: return .systemPurple
        case .paddleGrow: return .systemTeal
        case .laser: return .systemPink
        }
    }

    private func cleanUpOffscreenPowerUps() {
        let fallen = activePowerUps.filter { $0.position.y < 0 }
        guard !fallen.isEmpty else { return }
        fallen.forEach { $0.removeFromParent() }
        activePowerUps.removeAll { capsule in fallen.contains { $0 === capsule } }
    }

    private func applyPowerUp(_ type: PowerUpType) {
        switch type {
        case .multiBall:
            applyMultiBallPowerUp()
        case .paddleGrow:
            applyPaddleGrowPowerUp()
        case .laser:
            applyLaserPowerUp()
        }
    }

    private func applyMultiBallPowerUp() {
        guard !isWaitingForLaunch, let templateBall = balls.first, let velocity = templateBall.physicsBody?.velocity else { return }
        for angleOffset in GameScene.multiBallSpreadDegrees {
            let newBall = makeBall()
            newBall.position = templateBall.position
            addChild(newBall)
            balls.append(newBall)
            newBall.physicsBody?.velocity = GameMath.rotated(velocity, byDegrees: angleOffset)
        }
    }

    private func applyPaddleGrowPowerUp() {
        resizePaddle(toWidth: GameScene.paddleSize.width * GameScene.paddleGrowWidthMultiplier)
        paddleGrowExpiryTime = currentGameTime + GameScene.paddleGrowDuration
        viewModel.activatePowerUp(.paddleGrow)
    }

    private func updatePaddleGrowExpiry() {
        guard let expiry = paddleGrowExpiryTime, currentGameTime >= expiry else { return }
        resizePaddle(toWidth: GameScene.paddleSize.width)
        paddleGrowExpiryTime = nil
        viewModel.deactivatePowerUp(.paddleGrow)
    }

    private func applyLaserPowerUp() {
        laserExpiryTime = currentGameTime + GameScene.laserDuration
        lastLaserFireTime = currentGameTime - GameScene.laserFireInterval
        viewModel.activatePowerUp(.laser)
    }

    private func updateLaserFiring() {
        guard let expiry = laserExpiryTime else { return }
        guard currentGameTime < expiry else {
            laserExpiryTime = nil
            viewModel.deactivatePowerUp(.laser)
            return
        }
        guard currentGameTime - lastLaserFireTime >= GameScene.laserFireInterval else { return }
        lastLaserFireTime = currentGameTime
        fireLaserBolt()
    }

    private func fireLaserBolt() {
        let bolt = SKSpriteNode(color: .cyan, size: GameScene.laserBoltSize)
        bolt.position = CGPoint(x: paddle.position.x, y: paddle.position.y + paddle.size.height / 2)
        bolt.physicsBody = SKPhysicsBody(rectangleOf: GameScene.laserBoltSize)
        bolt.physicsBody?.isDynamic = true
        bolt.physicsBody?.affectedByGravity = false
        bolt.physicsBody?.categoryBitMask = PhysicsCategory.laserBolt
        bolt.physicsBody?.contactTestBitMask = PhysicsCategory.brick
        bolt.physicsBody?.collisionBitMask = PhysicsCategory.none
        bolt.physicsBody?.velocity = CGVector(dx: 0, dy: GameScene.laserBoltSpeed)
        addChild(bolt)
        activeLaserBolts.append(bolt)
    }

    private func cleanUpOffscreenLaserBolts() {
        let offscreen = activeLaserBolts.filter { $0.position.y > size.height }
        guard !offscreen.isEmpty else { return }
        offscreen.forEach { $0.removeFromParent() }
        activeLaserBolts.removeAll { bolt in offscreen.contains { $0 === bolt } }
    }

    // MARK: - Collisions

    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        if let ballBody = body(bodyA, bodyB, matching: PhysicsCategory.ball), let otherBody = other(bodyA, bodyB, than: ballBody) {
            handleBallContact(ballBody: ballBody, otherBody: otherBody)
        } else if let boltBody = body(bodyA, bodyB, matching: PhysicsCategory.laserBolt), let otherBody = other(bodyA, bodyB, than: boltBody) {
            handleLaserBoltContact(boltBody: boltBody, otherBody: otherBody)
        } else if let powerUpBody = body(bodyA, bodyB, matching: PhysicsCategory.powerUp), let otherBody = other(bodyA, bodyB, than: powerUpBody) {
            handlePowerUpContact(powerUpBody: powerUpBody, otherBody: otherBody)
        }
    }

    private func body(_ a: SKPhysicsBody, _ b: SKPhysicsBody, matching category: UInt32) -> SKPhysicsBody? {
        if a.categoryBitMask == category { return a }
        if b.categoryBitMask == category { return b }
        return nil
    }

    private func other(_ a: SKPhysicsBody, _ b: SKPhysicsBody, than body: SKPhysicsBody) -> SKPhysicsBody? {
        a === body ? b : a
    }

    private func handleBallContact(ballBody: SKPhysicsBody, otherBody: SKPhysicsBody) {
        switch otherBody.categoryBitMask {
        case PhysicsCategory.brick:
            handleBallBrickContact(otherBody)
        case PhysicsCategory.paddle:
            handleBallPaddleContact(ballBody)
        default:
            break
        }
    }

    private func handleBallBrickContact(_ brickBody: SKPhysicsBody) {
        guard let brick = brickBody.node as? SKSpriteNode else { return }
        destroyBrick(brick)
    }

    private func handleBallPaddleContact(_ ballBody: SKPhysicsBody) {
        guard let ballNode = ballBody.node else { return }
        let offset = (ballNode.position.x - paddle.position.x) / (paddle.size.width / 2)
        ballBody.velocity.dx += offset * GameScene.paddleInfluenceFactor
    }

    private func handleLaserBoltContact(boltBody: SKPhysicsBody, otherBody: SKPhysicsBody) {
        guard otherBody.categoryBitMask == PhysicsCategory.brick,
              let brick = otherBody.node as? SKSpriteNode,
              let bolt = boltBody.node as? SKSpriteNode else { return }
        bolt.removeFromParent()
        activeLaserBolts.removeAll { $0 === bolt }
        destroyBrick(brick)
    }

    private func handlePowerUpContact(powerUpBody: SKPhysicsBody, otherBody: SKPhysicsBody) {
        guard otherBody.categoryBitMask == PhysicsCategory.paddle,
              let capsule = powerUpBody.node as? PowerUpNode else { return }
        activePowerUps.removeAll { $0 === capsule }
        capsule.removeFromParent()
        applyPowerUp(capsule.type)
    }

    private func destroyBrick(_ brick: SKSpriteNode) {
        viewModel.addBrickScore()
        maybeDropPowerUp(from: brick.position)
        fadeOutAndRemove(brick)
        if bricksNode.children.count <= 1 {
            viewModel.markAsWon()
        }
    }

    private func fadeOutAndRemove(_ brick: SKSpriteNode) {
        let fadeAndScale = SKAction.group([
            .fadeOut(withDuration: GameScene.brickFadeDuration),
            .scale(to: 1.3, duration: GameScene.brickFadeDuration)
        ])
        brick.run(.sequence([fadeAndScale, .removeFromParent()]))
    }
}
