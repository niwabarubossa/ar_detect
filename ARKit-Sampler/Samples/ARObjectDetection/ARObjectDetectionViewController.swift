//
//  ARObjectDetectionViewController.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/20.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//
//  Thanks: https://github.com/hanleyweng/CoreML-in-ARKit

import UIKit
import ARKit
import CoreML
import Vision

class ARObjectDetectionViewController: UIViewController, ARSCNViewDelegate {

    //機械学習のモデル
    private var model: VNCoreMLModel!
    
    //場所の話
    private var screenCenter: CGPoint?

    //直列処理　順番に処理されるDispatch
    private let serialQueue = DispatchQueue(label: "com.shu223.arkit.objectdetection")
    
    //ただのスイッチ
    private var isPerformingCoreML = false
    //結果保存用の変数 画像解析リクエストによって生成された分類情報。
    private var latestResult: VNClassificationObservation?
    
    //自分で作成したオリジナルクラス　　3D座標空間での位置と変換を表すシーングラフの構造要素。
    private var tags: [TagNode] = []
    
    //背景が勝手にライブビデオカメラだよ〜
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    @IBOutlet var mlStateLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 12.0, *) {
            model = try! VNCoreMLModel(for: MobileNetV2Int8LUT().model)
        } else {
            // Fallback on earlier versions
        }
        
        sceneView.delegate = self
        sceneView.debugOptions = [SCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run()
        
        mlStateLabel.text = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
    }
    
    // MARK: - Private
    
    //どうやって実行するか、MLを呼び出されたとき何をするのか。　結果をlatestResultに代入している
    private func coreMLRequest() -> VNCoreMLRequest {
        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            guard let best = request.results?.first as? VNClassificationObservation  else {
                self.isPerformingCoreML = false
                return
            }
//            print("best: ")
            DispatchQueue.main.async(execute: {
//                self.mlStateLabel.text = "\(best.identifier) \(best.confidence * 100)"
                self.mlStateLabel.text = "niwa niwa niwa"
            })

            // don't tag when the result is enough confident
            if best.confidence < 0.3 {
                self.isPerformingCoreML = false
                return
            }

            //ここで、空間にタグを付与するものを
            if self.isFirstOrBestResult(result: best) {
                self.latestResult = best
                self.hitTest()
            }
            
            self.isPerformingCoreML = false
        })
        request.preferBackgroundProcessing = true

        request.imageCropAndScaleOption = .centerCrop
        
        return request
    }
    
    //実行を呼び出す
    private func performCoreML() {
//ここまで理解した　30minde
        serialQueue.async {
            guard !self.isPerformingCoreML else {return}
            guard let imageBuffer = self.sceneView.session.currentFrame?.capturedImage else {return}
            self.isPerformingCoreML = true
            
            let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer)
            let request = self.coreMLRequest()
            do {
                try handler.perform([request])
            } catch {
                print(error)
                self.isPerformingCoreML = false
            }
        }
    }
    
    private func isFirstOrBestResult(result: VNClassificationObservation) -> Bool {
        for tag in tags {
            guard let prevRes = tag.classificationObservation else {continue}
            if prevRes.identifier == result.identifier {
                // when the result is more confident, remove the older one
                if prevRes.confidence < result.confidence {
                    if let index = tags.firstIndex(of: tag) {
                        tags.remove(at: index)
                    }
                    tag.removeFromParentNode()
                    return true
                }
                // older one is better
                return false
            }
        }
        // first result
        return true
    }
    
    private func hitTest() {
        guard let frame = sceneView.session.currentFrame else {return}
        let state = frame.camera.trackingState
        switch state {
        case .normal:
            guard let pos = screenCenter else {return}
            DispatchQueue.main.async(execute: {
                self.hitTest(pos)
            })
        default:
            break
        }
    }
    
    //
    private func hitTest(_ pos: CGPoint) {
        let nodeResults = sceneView.hitTest(pos, options: [SCNHitTestOption.boundingBoxOnly: true])
        for nodeResult in nodeResults {
            if let overlappingTag = nodeResult.node.parent as? TagNode {
                // The tags seem overlapping, so let's replace with new one
                removeTag(tag: overlappingTag)
            }
        }
        
        let results1 = sceneView.hitTest(pos, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
        if let result = results1.first {
            addTag(for: result)
            return
        }
        
        let results2 = sceneView.hitTest(pos, types: .featurePoint)
        if let result = results2.first {
            addTag(for: result)
        }
    }

    private func addTag(for hitTestResult: ARHitTestResult) {
        let tagNode = TagNode()
        tagNode.transform = SCNMatrix4(hitTestResult.worldTransform)
        tags.append(tagNode)
        tagNode.classificationObservation = latestResult
        sceneView.scene.rootNode.addChildNode(tagNode)
    }

    private func removeTag(tag: TagNode) {
        tag.removeFromParentNode()
        guard let index = tags.firstIndex(of: tag) else {return}
        tags.remove(at: index)
    }
    
    private func reset() {
        for child in sceneView.scene.rootNode.childNodes {
            if child is TagNode {
                guard let tag = child as? TagNode else {fatalError()}
                removeTag(tag: tag)
            }
        }
    }

    // MARK: - ARSCNViewDelegate
    
    //アクション、アニメーション、および物理が評価される前に発生する必要がある更新を実行するようデリゲートに指示します。
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        performCoreML()
    }

    // MARK: - ARSessionObserver
    
    //ARKitのデバイス位置の追跡品質の更新時に呼ばれる。
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
    
    // MARK: - Actions
    
    @IBAction func resetBtnTapped(_ sender: UIButton) {
        reset()
    }
}

