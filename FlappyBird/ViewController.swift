//
//  ViewController.swift
//  FlappyBird
//
//  Created by Dan Inano on 2020/09/27.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //SKView型荷変更する
        let skView = self.view as! SKView
        //FPSを表示する
        skView.showsFPS = true
        //NodeCountを表示する
        skView.showsNodeCount = true
        //ビューと同じサイズでシーンを作成する
        let scene = GameScene(size:skView.frame.size)
        //ビューにシーンを表示する
        skView.presentScene(scene)
    }


}

