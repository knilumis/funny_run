import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var jumpCount = 0  // Zıplama sayacını tanımlıyoruz
    var scoreLabel: SKLabelNode!
    var bonusLabel: SKLabelNode!
    var bonusTimerLabel: SKLabelNode!
    var scoreIncreaseLabel: SKLabelNode!
    var score = 0
    var maxObstacleHeight: CGFloat = 100  // Engellerin maksimum başlangıç yüksekliği
    var obstacleSpeed: CGFloat = 200  // Engellerin hareket hızı
    var bonusActiveTime: Int = 0  // Bonusun aktif kalma süresi
    var isShieldActive = false  // Koruma kalkanının aktif olup olmadığını takip eden değişken

    // Çarpışma kategorilerini tanımlıyoruz
    let playerCategory: UInt32 = 0x1 << 0  // 1
    let obstacleCategory: UInt32 = 0x1 << 1  // 2
    let groundCategory: UInt32 = 0x1 << 2  // 4
    let bonusCategory: UInt32 = 0x1 << 3  // 8
    let scoreCategory: UInt32 = 0x1 << 4  // 16
    let shieldCategory: UInt32 = 0x1 << 5  // 32 (Koruma kalkanı için yeni kategori)

    override func didMove(to view: SKView) {
        // Fizik dünyası ve çarpışma delegesi ayarı
        self.physicsWorld.contactDelegate = self
        
        // Arka plan görselini ekleyelim
        let background = SKSpriteNode(imageNamed: "sky_blue_background")
        background.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        background.size = self.size
        background.zPosition = -1  // Arka plan her şeyin arkasında olacak
        self.addChild(background)

        // Yerçekimi ve fizik özellikleri
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        // Karakter görselini tanımlayalım ve animasyon ekleyelim
        player = SKSpriteNode(imageNamed: "blue_square_character")
        player.size = CGSize(width: 50, height: 50)
        player.position = CGPoint(x: self.size.width * 0.2, y: self.size.height * 0.5)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.isDynamic = true
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = obstacleCategory | groundCategory | bonusCategory | scoreCategory | shieldCategory
        player.physicsBody?.collisionBitMask = groundCategory | obstacleCategory
        self.addChild(player)
        addPlayerAnimation()

        // Zemin ekleme
        let ground = SKSpriteNode(imageNamed: "green_ground")
        ground.size = CGSize(width: self.size.width, height: 50)
        ground.position = CGPoint(x: self.size.width / 2, y: ground.size.height / 2)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = groundCategory
        self.addChild(ground)
        
        // Skor ve bonus sayacı ekleyelim
        addScoreLabel()
        addBonusLabels()

        // Engel ve bonus oluşturma işlemlerini başlatalım
        startSpawningObstacles()
        startSpawningBonuses()
    }

    func addPlayerAnimation() {
        // Karakter animasyonu için texture'lar oluşturma (Koşma ve zıplama animasyonu)
        var runTextures: [SKTexture] = []
        for i in 1...4 {
            runTextures.append(SKTexture(imageNamed: "blue_square_character"))
        }
        let runAnimation = SKAction.repeatForever(SKAction.animate(with: runTextures, timePerFrame: 0.1))
        player.run(runAnimation)
    }

    func addScoreLabel() {
        // Skor etiketini oluşturup sahneye ekleyelim
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.black
        scoreLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 80)
        scoreLabel.zPosition = 10
        scoreLabel.text = "Skor: \(score)"
        self.addChild(scoreLabel)
    }

    func addBonusLabels() {
        // Bonus bildirim etiketi
        bonusLabel = SKLabelNode(fontNamed: "Arial")
        bonusLabel.fontSize = 24
        bonusLabel.fontColor = SKColor.green
        bonusLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 120)
        bonusLabel.zPosition = 10
        bonusLabel.text = ""
        self.addChild(bonusLabel)

        // Bonus süre etiketi
        bonusTimerLabel = SKLabelNode(fontNamed: "Arial")
        bonusTimerLabel.fontSize = 24
        bonusTimerLabel.fontColor = SKColor.red
        bonusTimerLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 150)
        bonusTimerLabel.zPosition = 10
        bonusTimerLabel.text = ""
        self.addChild(bonusTimerLabel)

        // Skor artışı bildirimi
        scoreIncreaseLabel = SKLabelNode(fontNamed: "Arial")
        scoreIncreaseLabel.fontSize = 24
        scoreIncreaseLabel.fontColor = SKColor.yellow
        scoreIncreaseLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height - 180)
        scoreIncreaseLabel.zPosition = 10
        scoreIncreaseLabel.text = ""
        self.addChild(scoreIncreaseLabel)
    }

    func startSpawningObstacles() {
        // Engelleri rastgele aralıklarla tekrarlamak için aksiyon
        let spawn = SKAction.run(spawnObstacle)
        let delay = SKAction.wait(forDuration: randomDelay())
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnForever, withKey: "spawnObstacles")
    }

    func startSpawningBonuses() {
        // Rastgele bonus ve skor artırıcı puanlar oluşturma
        let spawnBonus = SKAction.run(spawnBonusOrScore)
        let bonusDelay = SKAction.wait(forDuration: 10.0)
        let spawnBonusThenDelay = SKAction.sequence([spawnBonus, bonusDelay])
        let spawnBonusForever = SKAction.repeatForever(spawnBonusThenDelay)
        self.run(spawnBonusForever)
    }

    func randomDelay() -> TimeInterval {
        return TimeInterval(CGFloat.random(in: 1.5...2.5))
    }

    func spawnObstacle() {
        // Engel yüksekliğini rastgele belirleyelim
        let randomHeight = CGFloat.random(in: 50...maxObstacleHeight)
        
        // Engel ekleme
        let obstacle = SKSpriteNode(imageNamed: "rectangular_obstacle")
        obstacle.size = CGSize(width: 50, height: randomHeight)
        let groundHeight = 50
        obstacle.position = CGPoint(x: self.size.width + obstacle.size.width, y: CGFloat(groundHeight) + obstacle.size.height / 2)
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.categoryBitMask = obstacleCategory
        obstacle.physicsBody?.contactTestBitMask = playerCategory
        self.addChild(obstacle)
        
        // Hareketli engel yapma (Hareket eden engel oluştur)
        let moveLeft = SKAction.moveBy(x: -self.size.width - obstacle.size.width, y: CGFloat.random(in: -50...50), duration: TimeInterval(self.size.width / obstacleSpeed))
        let remove = SKAction.removeFromParent()
        let increaseScore = SKAction.run { [weak self] in
            self?.score += 1
            self?.scoreLabel.text = "Skor: \(self?.score ?? 0)"
            
            // Skor arttıkça engel yüksekliği ve hızı artsın
            if let score = self?.score, score % 5 == 0 {
                self?.maxObstacleHeight += 30
                self?.obstacleSpeed += 50
            }
        }
        obstacle.run(SKAction.sequence([moveLeft, increaseScore, remove]))
    }

    func spawnBonusOrScore() {
        // Bonus veya skor artırıcı rastgele seçilir
        let randomChoice = Int.random(in: 0...2) // Artık kalkan bonusunu da ekliyoruz
        if randomChoice == 0 {
            spawnBonusPoint()
        } else if randomChoice == 1 {
            spawnScorePoint()
        } else {
            spawnShield()
        }
    }

    func spawnBonusPoint() {
        // Hız artırıcı bonus puan
        let bonus = SKSpriteNode(imageNamed: "star_bonus_icon")
        bonus.size = CGSize(width: 50, height: 50)
        let maxJumpHeight = player.position.y + 100
        bonus.position = CGPoint(x: self.size.width + bonus.size.width, y: CGFloat.random(in: player.position.y...maxJumpHeight))
        bonus.physicsBody = SKPhysicsBody(rectangleOf: bonus.size)
        bonus.physicsBody?.isDynamic = false
        bonus.physicsBody?.categoryBitMask = bonusCategory
        bonus.physicsBody?.contactTestBitMask = playerCategory
        bonus.zPosition = 5
        self.addChild(bonus)

        // Bonus hareketi
        let moveLeft = SKAction.moveBy(x: -self.size.width - bonus.size.width, y: 0, duration: 5.0)
        let remove = SKAction.removeFromParent()
        let collectBonus = SKAction.run { [weak self] in
            self?.activateSpeedBoost()
        }
        bonus.run(SKAction.sequence([moveLeft, collectBonus, remove]))
    }

    func spawnScorePoint() {
        // Skor artırıcı puan
        let scorePoint = SKSpriteNode(imageNamed: "medal_score_icon")
        scorePoint.size = CGSize(width: 50, height: 50)
        let maxJumpHeight = player.position.y + 100
        scorePoint.position = CGPoint(x: self.size.width + scorePoint.size.width, y: CGFloat.random(in: player.position.y...maxJumpHeight))
        scorePoint.physicsBody = SKPhysicsBody(rectangleOf: scorePoint.size)
        scorePoint.physicsBody?.isDynamic = false
        scorePoint.physicsBody?.categoryBitMask = scoreCategory
        scorePoint.physicsBody?.contactTestBitMask = playerCategory
        scorePoint.zPosition = 5
        self.addChild(scorePoint)

        // Skor artırıcı hareketi
        let moveLeft = SKAction.moveBy(x: -self.size.width - scorePoint.size.width, y: 0, duration: 5.0)
        let remove = SKAction.removeFromParent()
        let increaseScore = SKAction.run { [weak self] in
            let scoreIncrease = 10
            self?.score += scoreIncrease
            self?.scoreLabel.text = "Skor: \(self?.score ?? 0)"
            self?.showScoreIncrease(scoreIncrease)
        }
        scorePoint.run(SKAction.sequence([moveLeft, increaseScore, remove]))
    }

    func spawnShield() {
        // Koruma kalkanı bonusu
        let shield = SKSpriteNode(imageNamed: "shield_icon")
        shield.size = CGSize(width: 50, height: 50)
        let maxJumpHeight = player.position.y + 100
        shield.position = CGPoint(x: self.size.width + shield.size.width, y: CGFloat.random(in: player.position.y...maxJumpHeight))
        shield.physicsBody = SKPhysicsBody(rectangleOf: shield.size)
        shield.physicsBody?.isDynamic = false
        shield.physicsBody?.categoryBitMask = shieldCategory
        shield.physicsBody?.contactTestBitMask = playerCategory
        shield.zPosition = 5
        self.addChild(shield)

        // Koruma kalkanı hareketi
        let moveLeft = SKAction.moveBy(x: -self.size.width - shield.size.width, y: 0, duration: 5.0)
        let remove = SKAction.removeFromParent()
        let collectShield = SKAction.run { [weak self] in
            self?.activateShield()
        }
        shield.run(SKAction.sequence([moveLeft, collectShield, remove]))
    }

    func activateSpeedBoost() {
        // Hız artırıcı bonus etkisi
        bonusLabel.text = "Hız Artışı!"
        bonusActiveTime = 5
        updateBonusTimerLabel()

        // Hızı artır
        obstacleSpeed += 100

        // Sayaç başlangıcı
        let bonusTimerAction = SKAction.repeat(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.bonusActiveTime -= 1
                self?.updateBonusTimerLabel()
                if self?.bonusActiveTime == 0 {
                    self?.endSpeedBoostEffect()
                }
            }
        ]), count: bonusActiveTime)

        self.run(bonusTimerAction, withKey: "bonusTimer")
    }

    func activateShield() {
        // Koruma kalkanı bonusu etkisi
        bonusLabel.text = "Kalkan Aktif!"
        isShieldActive = true
        
        // Koruma süresi (örneğin 5 saniye)
        let shieldDuration = 5.0
        let deactivateShield = SKAction.run { [weak self] in
            self?.isShieldActive = false
            self?.bonusLabel.text = ""
        }
        self.run(SKAction.sequence([SKAction.wait(forDuration: shieldDuration), deactivateShield]), withKey: "shieldTimer")
    }

    func updateBonusTimerLabel() {
        bonusTimerLabel.text = "Bonus Süresi: \(bonusActiveTime)"
    }

    func endSpeedBoostEffect() {
        // Hız artırıcı bonus etkisi bittiğinde
        bonusLabel.text = ""
        bonusTimerLabel.text = ""
        obstacleSpeed -= 100
        self.removeAction(forKey: "bonusTimer")
    }

    func showScoreIncrease(_ increase: Int) {
        // Skor artışı bildirimi
        scoreIncreaseLabel.text = "Skor +\(increase)"
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let clearText = SKAction.run { [weak self] in
            self?.scoreIncreaseLabel.text = ""
            self?.scoreIncreaseLabel.alpha = 1.0
        }
        scoreIncreaseLabel.run(SKAction.sequence([fadeOut, clearText]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Çift zıplama kontrolü
        if jumpCount < 2 {
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 95))
            jumpCount += 1
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        // Çarpışma tespiti
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if collision == (playerCategory | obstacleCategory) {
            if isShieldActive {
                // Kalkan aktifse çarpışma etkilenmez
                return
            }
            print("Çarpışma oldu!")
            handleCollision()
        } else if collision == (playerCategory | groundCategory) {
            jumpCount = 0
        } else if collision == (playerCategory | bonusCategory) {
            contact.bodyB.node?.removeFromParent()
            activateSpeedBoost()
        } else if collision == (playerCategory | scoreCategory) {
            contact.bodyB.node?.removeFromParent()
            let scoreIncrease = 10
            score += scoreIncrease
            scoreLabel.text = "Skor: \(score)"
            showScoreIncrease(scoreIncrease)
        } else if collision == (playerCategory | shieldCategory) {
            contact.bodyB.node?.removeFromParent()
            activateShield()
        }
    }

    func handleCollision() {
        // Engel oluşturma işlemini durdur
        self.removeAction(forKey: "spawnObstacles")

        // Karakterin devrilme hareketini görmesini sağla
        player.physicsBody?.isDynamic = true
        
        // 2 saniye sonra menüyü göster
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(showGameOverMenu), userInfo: nil, repeats: false)
    }

    @objc func showGameOverMenu() {
        let gameOverLabel = SKLabelNode(fontNamed: "Arial")
        gameOverLabel.text = "Oyun Bitti!"
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = SKColor.red
        gameOverLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 40)
        gameOverLabel.zPosition = 2
        self.addChild(gameOverLabel)
        
        let retryButton = SKLabelNode(fontNamed: "Arial")
        retryButton.text = "Tekrar Dene"
        retryButton.fontSize = 30
        retryButton.fontColor = SKColor.blue
        retryButton.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 - 40)
        retryButton.zPosition = 2
        retryButton.name = "retryButton"
        self.addChild(retryButton)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Menüdeki "Tekrar Dene" seçeneği için dokunma kontrolü
        if let touch = touches.first {
            let location = touch.location(in: self)
            let nodesAtLocation = nodes(at: location)
            for node in nodesAtLocation {
                if node.name == "retryButton" {
                    resetGame()
                }
            }
        }
    }

    func resetGame() {
        // Yeni bir sahne oluştur ve sun
        let newScene = GameScene(size: self.size)
        newScene.scaleMode = .resizeFill
        self.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0.5))
    }
}
