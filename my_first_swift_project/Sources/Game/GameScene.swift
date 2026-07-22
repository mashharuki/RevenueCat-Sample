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

    private let viewModel: GameViewModel
    private let paddle = SKSpriteNode(color: .white, size: GameScene.paddleSize)
    private let ball = SKShapeNode(circleOfRadius: GameScene.ballRadius)
    private let bricksNode = SKNode()
    private var isWaitingForLaunch = true

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
        setUpBall()
        addChild(bricksNode)
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
        paddle.physicsBody = SKPhysicsBody(rectangleOf: GameScene.paddleSize)
        paddle.physicsBody?.isDynamic = false
        paddle.physicsBody?.categoryBitMask = PhysicsCategory.paddle
        paddle.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        addChild(paddle)
    }

    private func setUpBall() {
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
        addChild(ball)
        resetBallPosition()
    }

    // MARK: - Game lifecycle

    func startGame() {
        buildBricks()
        resetBallPosition()
        isWaitingForLaunch = true
        launchBall()
    }

    func resetGame() {
        removeAllBricks()
        startGame()
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

    private func resetBallPosition() {
        ball.position = CGPoint(x: paddle.position.x, y: paddle.position.y + GameScene.paddleSize.height)
        ball.physicsBody?.velocity = .zero
        isWaitingForLaunch = true
    }

    private func launchBall() {
        guard isWaitingForLaunch else { return }
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
        let halfWidth = GameScene.paddleSize.width / 2
        let clampedX = GameMath.clamp(touchX, min: halfWidth, max: size.width - halfWidth)
        paddle.position.x = clampedX
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        clampBallSpeed()
        checkBallFellBelowPaddle()
    }

    private func clampBallSpeed() {
        guard let velocity = ball.physicsBody?.velocity, !isWaitingForLaunch else { return }
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        guard speed > 0 else { return }
        let clampedSpeed = GameMath.clamp(speed, min: GameScene.minBallSpeed, max: GameScene.maxBallSpeed)
        guard clampedSpeed != speed else { return }
        let scale = clampedSpeed / speed
        ball.physicsBody?.velocity = CGVector(dx: velocity.dx * scale, dy: velocity.dy * scale)
    }

    private func checkBallFellBelowPaddle() {
        guard !isWaitingForLaunch, ball.position.y < 0 else { return }
        handleBallLost()
    }

    private func handleBallLost() {
        resetBallPosition()
        let hasLivesRemaining = viewModel.loseLife()
        guard hasLivesRemaining else { return }
        let relaunch = SKAction.sequence([
            .wait(forDuration: GameScene.relaunchDelay),
            .run { [weak self] in self?.launchBall() }
        ])
        run(relaunch)
    }

    // MARK: - Collisions

    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = (contact.bodyA, contact.bodyB)
        guard let otherBody = ballContactOtherBody(in: bodies) else { return }

        switch otherBody.categoryBitMask {
        case PhysicsCategory.brick:
            handleBallBrickContact(otherBody)
        case PhysicsCategory.paddle:
            handleBallPaddleContact()
        default:
            break
        }
    }

    private func ballContactOtherBody(in bodies: (SKPhysicsBody, SKPhysicsBody)) -> SKPhysicsBody? {
        if bodies.0.categoryBitMask == PhysicsCategory.ball { return bodies.1 }
        if bodies.1.categoryBitMask == PhysicsCategory.ball { return bodies.0 }
        return nil
    }

    private func handleBallBrickContact(_ brickBody: SKPhysicsBody) {
        guard let brick = brickBody.node as? SKSpriteNode else { return }
        viewModel.addBrickScore()
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

    private func handleBallPaddleContact() {
        let offset = (ball.position.x - paddle.position.x) / (GameScene.paddleSize.width / 2)
        ball.physicsBody?.velocity.dx += offset * GameScene.paddleInfluenceFactor
    }
}
