//
//  GameScene.swift
//  FlappyBird
//
//  Created by Dan Inano on 2020/09/27.
//

import SpriteKit

class GameScene: SKScene , SKPhysicsContactDelegate{
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    
    
    
    //衝突カテゴリー
    let birdCategory: UInt32 =  1 << 0  //0...00001
    let groundCategory: UInt32 = 1 << 1 //0...00010
    let wallCategory: UInt32 = 1 << 2   //0...00100
    let scoreCategory: UInt32 = 1 << 3  //0...01000
    
    //スコア用
    var score = 0
    let userDefaults:UserDefaults = UserDefaults.standard
    var bestScoreLabelNode:SKLabelNode!
    var scoreLabelNode:SKLabelNode!
    
    
    override func didMove(to view: SKView) {
        
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0 , dy: -4)
        physicsWorld.contactDelegate = self
        
        //背景色を設定
        backgroundColor = UIColor(red:0.15,green:0.75,blue:0.90,alpha:1)
        
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //各種スプライトを生成する処理メソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        
        
        setupScoreLabel()
        
        
  
    }
    func setupGround(){
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest  //.nearestは処理優先　.linerは画質優先
        
         //地面の必要枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを設定
        
        //左方向に画像一枚分スクロールするアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration:5)
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration:0)
        //左スクロール→元の位置を延々と繰り返すアクション
        let repeatscrollGround = SKAction.repeatForever(SKAction.sequence([moveGround,resetGround]))
        
        //groundのスプライトを配置する
        for i in 0..<needNumber{
            //テクスチャを指定してスプライトを作成する
            let sprite = SKSpriteNode(texture: groundTexture)
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            sprite.physicsBody?.isDynamic = false
            
            //衝突のカテゴリーを設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //スプライトにアクションを設定する
            sprite.run(repeatscrollGround)
            //シーンにスプライトを追加する
            scrollNode.addChild(sprite)
        }
        
    }
    func setupCloud(){
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        let repeatscrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        
        for i in 0..<needCloudNumber{
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番うしろになるようにする
            
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            sprite.run(repeatscrollCloud)
            
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall(){
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear //当たり判定を伴うため
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        //画面が今で移動するアクションを設定
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        //自身を取り除くアクションを設定
        let removeWall = SKAction.removeFromParent()
        //2つのアクションを交互に実行する
        let wallAnimation = SKAction.sequence([moveWall,removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        //鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
        let slit_length = birdSize.height * 3
        //隙間位置の上下の振れ幅を鳥のサイズの3倍とする
        let random_y_range = birdSize.height * 3
        // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height + groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        //壁を生成するアクション
        let createWallAnimation = SKAction.run({
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0 )
            wall.zPosition = -50 //雲より手前、壁より奥
            
            //0~random_y_rangeまでのランダムな値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            //Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            //下の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //物理演算を設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            //衝突しても動かない
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            //上の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //物理演算を設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            //衝突しても動かない
            upper.physicsBody?.isDynamic = false
            
            
            wall.addChild(upper)
            
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2,y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory  //自身のカテゴリを設定
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory //衝突相手を設定
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        
        // 次の壁作成までの時間待ちのアクションを生成
        let waitAnimation = SKAction.wait(forDuration: 2)
        // 壁作成→時間待ちを得＝無限に繰り返す設定
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
        

        
        
        
    }
    
    func setupBird(){
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //2種類の画像を交互に表示するアニメーションを作成
        let TexturesAnimation = SKAction.animate(with:[birdTextureA,birdTextureB],timePerFrame: 0.2)
        let flap = SKAction.repeatForever(TexturesAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2,y: self.frame.size.height * 0.7)
        
        //物理演算を追加する
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //ぶつかった時に回転を許さない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{
            //鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            //縦方向の力を加える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0,dy: 15))
        }else{ if bird.speed == 0{
            restart()
        }
            
        }
        
    }
    
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }

        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score: \(score)"
            //ベストスコアを更新する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore{
                bestScore = score
                bestScoreLabelNode.text = "Best Score: \(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
        } else {
            // 壁か地面と衝突した
            print("GameOver")

            // スクロールを停止させる
            scrollNode.speed = 0

            bird.physicsBody?.collisionBitMask = groundCategory

            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func restart(){
        score = 0
        scoreLabelNode.text = "Score: \(score)"
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y:self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y:self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score: \(bestScore)"
        self.addChild(bestScoreLabelNode)
    }

}
