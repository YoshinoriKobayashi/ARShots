//
//  ViewController.swift
//  ARShots
//
//  Created by yoshiiikoba on 2020/05/12.
//  Copyright © 2020 TickleCode. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var visNode:SCNNode!
    var mainContainer: SCNNode!
    var gameHasStarted = false
    var foundSurface = false
    var gamePos = SCNVector3Make(0.0, 0.0, 0.0)
    var scoreLbl: UILabel!
    
    // プロパティオブザーバ
    var score = 0 {
        // 値が変更された直後に実行される
        didSet {
            // 画面の撃墜数を更新
            scoreLbl.text = "\(score)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // シーンを作成して登録
        sceneView.scene = SCNScene(named: "art.scnassets/scene.scn")!
        
        // 特徴点を表示する
        // showWorldOrigin AR の原点座標を表示する
        // showFeaturePoints 検出された特徴点を表示する
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
    }
    
    // viewWillAppear
    // ビューコントローラのビューがビュー階層に追加される前
    // およびビューを表示するためのアニメーションが設定される前に呼び出されます。
    // このメソッドをオーバーライドして、ビューの表示に関連したカスタムタスクを実行することができます。
    // 例えば、このメソッドを使用して、ステータスバーの向きやスタイルを変更して、
    // 表示されるビューの向きやスタイルに合わせて調整することができます。
    // このメソッドをオーバーライドする場合は、実装のどこかの時点で super を呼び出す必要があります。
    override func viewWillAppear(_ animated: Bool) {
        
        // super を呼び出す
        super.viewWillAppear(animated)
        
        // ARKit は特徴点の検出～ AR の表示までをカメラ画像の表示までを１つのセッションとして管理
        let configuration = ARWorldTrackingConfiguration()
        // run メソッドを実行することでセッションを開始
        // セッショ ンを開始すると、カメラで撮影した映像を解析して、特徴点を検出し、
        // それを加速度センサやジャイロセンサの値と合わせて解析し、実空間の構造認識が始まります。
        sceneView.session.run(configuration)
    }
    
    // viewWillDisappear
    /* ビューがビュー階層から削除されたときに呼び出されます。
        このメソッドは、ビューが実際に削除される前、アニメーションが設定される前に呼び出されます。
        例えば、ビューが最初に表示されたときに viewDidAppear(_:)メソッドで
        行ったステータスバーの向きやスタイルの変更を元に戻すために、
        このメソッドを使用することができます。
        このメソッドをオーバーライドする場合は、実装のどこかの時点で super を呼び出す必要があります。 */
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func randomPos() -> SCNVector3 {
        let randX = (Float(arc4random_uniform(200)) / 100.0) - 1.0
        let randY = (Float(arc4random_uniform(200)) / 100.0) + 1.5

        /* SceneKit は、ノードや頂点の位置、サーフェス法線、スケールやトランスフォームなど、
            さまざまな目的のために 3成分ベクトルを使用します。
            異なるベクトルコンポーネントは、ベクトルが使用されているコンテキストに
            基づいて解釈されるべきです。 */
        return SCNVector3Make(randX, randY, -5.0)
    }
    
    // 飛行機を追加
    @objc func addPlane() {
        // シーンからノードを検索
        let plane = sceneView.scene.rootNode.childNode(withName:"plane",recursively:false)?.copy() as! SCNNode
        plane.position = randomPos()
        plane.isHidden = false
        
        mainContainer.addChildNode(plane)
        
        // 飛行機の速度
        let randSpeed = Float(arc4random_uniform(3) + 3)
        let planeAnimation = SCNAction.sequence([SCNAction.wait(duration: 10.0),SCNAction.fadeOut(duration: 1.0),SCNAction.removeFromParentNode()])
        
        plane.physicsBody = SCNPhysicsBody(type:.dynamic,shape: nil)
        plane.physicsBody?.isAffectedByGravity = false
        plane.physicsBody?.applyForce(SCNVector3Make(0.0, 0.0, randSpeed), asImpulse: true)
        plane.runAction(planeAnimation)
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(addPlane), userInfo: nil, repeats: false)
    }
    
    // MARK:- Scene Handing
    // touchesBegan(_:with:)
    // ビューまたはウィンドウで1つ以上の新しいタッチが発生したことをこのオブジェクトに通知します。
    // 
    // touches
    // イベントで表されるイベントの開始フェーズのタッチを表す UITouchインスタンスのセット。
    // ビュー内のタッチの場合、このセットにはデフォルトで1つのタッチのみが含まれます。
    // 複数のタッチを受信するには、ビューの isMultipleTouchEnabled プロパティを 
    // true に設定する必要があります。
    // 
    // event: UIEvent
    // タッチが属するイベント。
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // ゲームがスタートしている。
        if gameHasStarted {
            // 最初のタッチがとれた
            guard let touch = touches.first else {
                return
            }
            // タッチした場所
            let touchLocation = touch.location(in: view)

            /* hitTest(_:options:)
             レンダリングされたイメージのポイントに対応するオブジェクトをレンダラーのシーンで検索します。
             touchLocation
             シーンレンダラーのスクリーン空間（ビュー、レイヤー、または GPU ビューポート）座標系内の点。
             options
             検索に影響を与えるオプションの辞書。許容できる値については、ヒットテストオプションキーを参照
             戻り値
             検索結果を表す SCNHitTestResult オブジェクトの配列。
             
             レンダリングされたスクリーン座標空間の 2D 点は、3D シーン座標空間のラインセグメントに
             沿った任意の点を参照することができます。ヒットテストは、この線分に沿って配置されたシーンの
             要素を見つけるプロセスです。例えば、SceneKit ビューのクリックイベントに対応するジオメトリを
             見つけるには、この方法を使用します。
            */
            guard let hitTestTouch = sceneView.hitTest(touchLocation, options:nil).first else {
                return
            }
            let touchedNode = hitTestTouch.node
            
            guard touchedNode.name == "plane" else {
                return
            }
            // physicsBody
            // 重力や摩擦などの物理計算を計算するライブラリ
            // isAffectedByGravity
            // シーンの一定の重力が身体を加速させるかどうかを判断するブール値。
            touchedNode.physicsBody?.isAffectedByGravity = true
            // applyTorque(_:asImpulse:)
            // ボディに正味のトルクや角運動量の変化を与えます。
            // SCNVector4Make(_:_:_:_:)
            // 個々のコンポーネント値から作成された新しい4成分ベクトルを返します。
            touchedNode.physicsBody?.applyTorque(SCNVector4Make(0.0, 0.3, 1.0, 1.0), asImpulse: true)
            // 撃墜数を増やす
            score += 1
            
            /* 
             SCNParticleSystem
             指定した一般的な挙動を持つ高レベルのシミュレーションを用いて、
             小画像スプライトのシステムをアニメーション化してレンダリングするオブジェクトです。
             */
            let explosion = SCNParticleSystem(named:"Explosion.scnp",inDirectory: nil)!
            // ノードにパーティクルシステムをアタッチします。
            touchedNode.addParticleSystem(explosion)
            
        } else {
            // ゲームがスタートしていない
            
             guard foundSurface else { return }
            
            gameHasStarted = true
            visNode.removeFromParentNode()
            
            // Score LBL
            scoreLbl = UILabel(frame: CGRect(x:0.0,y:view.frame.height * 0.05,width: view.frame.width, height: view.frame.height * 0.01))
            scoreLbl.textColor = .yellow
            scoreLbl.font = UIFont(name:"Arial", size: view.frame.width * 0.1)
            scoreLbl.text = "0"
            scoreLbl.textAlignment = .center
            
            view.addSubview(scoreLbl)
            
            // Main Container
            mainContainer = sceneView.scene.rootNode.childNode(withName: "mainContainer",recursively:false)!
            mainContainer.isHidden = false
            mainContainer.position = gamePos
            
            // Lighting（Ambient）
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.color = UIColor.white
            ambientLight.intensity = 300.0
            
            let ambientLightNode = SCNNode()
            ambientLightNode.light = ambientLight
            ambientLightNode.position.y = 2.0
            
            mainContainer.addChildNode(ambientLightNode)
            
            // Lighting (Omnidirectional)
            let omniLight = SCNLight()
            omniLight.type = .omni
            omniLight.color = UIColor.white
            omniLight.intensity = 1000.0
            
            let omniLightNode = SCNNode()
            omniLightNode.light = omniLight
            omniLightNode.position.y = 3.0
            
            mainContainer.addChildNode(omniLightNode)
            
            addPlane()
        }
    }
    
    // renderer(_:updateAtTime:)
    // アクション、アニメーション、物理が評価される前に必要な更新を実行するようデリゲートに指示します。
    // SCNSceneRenderer renderer シーンのレンダリングを担当する SceneKit オブジェクト。
    // updateAtTime time 現在のシステム時間を秒単位で指定。
    // 
    // SceneKit は、シーンを表示している SCNView オブジェクト（または他の SCNSceneRenderer
    // オブジェクト）が一時停止していない限り、このメソッドをフレームごとに 1 回だけ呼び出します。
    // レンダリングループにゲームロジックを追加するには、このメソッドを実装してください。
    // このメソッドでシーングラフに変更を加えた場合、表示されているシーンに即座に反映されます。
    // つまり、SceneKitはシーンをレンダリングするために使用するプレゼンテーションノード
    // の階層を即座に更新します（変更を「バッチ」するために SCNTransaction クラスを使用するのではなく）。
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard !gameHasStarted else { return }
        guard let hitTest = sceneView.hitTest(CGPoint(x:view.frame.midX, y:view.frame.midY), types: [.existingPlane,.featurePoint,.estimatedHorizontalPlane]).last else { return }
        
        let transform = SCNMatrix4(hitTest.worldTransform)
        gamePos = SCNVector3Make(transform.m41,transform.m42,transform.m43)
        
        if visNode == nil {
            let visPlane = SCNPlane(width: 0.3, height: 0.3)
            visPlane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "tracker")
            
            visNode = SCNNode(geometry: visPlane)
            visNode.eulerAngles.x = .pi * -0.5
            
            sceneView.scene.rootNode.addChildNode(visNode)
        }
        
        visNode.position = gamePos
        foundSurface = true
        
    }
    
}
