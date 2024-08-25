import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SKView olarak cast edilecek view'i alıyoruz
        if let view = self.view as! SKView? {
            // Sahneyi manuel olarak boyutlandırıyoruz
            let scene = GameScene(size: view.bounds.size)  // Doğrudan ekran boyutunu kullanarak sahne oluştur
            scene.scaleMode = .resizeFill  // Sahnenin boyutunu ekran boyutuna göre doldur
            
            // Sahneyi SKView içinde sunuyoruz
            view.presentScene(scene)
            
            // Performans için bazı SKView ayarları
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
