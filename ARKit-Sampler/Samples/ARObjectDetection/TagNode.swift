//
//  TagAnchor.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/20.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import SceneKit
import Vision
import Firebase
import FirebaseCore
import FirebaseFirestore

//SCN Node 3D座標空間での位置と変換を表すシーングラフの構造要素。ジオメトリ、ライト、カメラ、またはその他の表示可能なコンテンツを接続できます
class TagNode: SCNNode {
    
    let db = Firestore.firestore()
    
    var savedIdentifierArray:[String] = []
    var isFirst:Bool = true

    //ここに外部から識別情報が付与される
    var classificationObservation: VNClassificationObservation? {
        didSet {
//            addTextNode()
        }
    }
    
    var tagContent: VNClassificationObservation? {
        didSet {
//            addTextNode()
        }
    }
    
    var firestore_content:String = "no data"{
        didSet{
            addTextNode()
        }
    }
    

    
    private func addTextNode() {
        //ここが、テキスト代入される。空間に実際に表示される識別結果
        if self.firestore_content != "no data" && self.isFirst {
            self.isFirst = false
            let textNode = SCNNode.textNode(text: self.firestore_content)
            DispatchQueue.main.async(execute: {
                self.addChildNode(textNode)
            })
            addSphereNode(color: UIColor.green)
        }
    }
    
    private func addSphereNode(color: UIColor) {
        DispatchQueue.main.async(execute: {
            let sphereNode = SCNNode.sphereNode(color: color)
            self.addChildNode(sphereNode)
        })
    }    
}
