//
//  TagAnchor.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/09/20.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import SceneKit
import Vision

//SCN Node 3D座標空間での位置と変換を表すシーングラフの構造要素。ジオメトリ、ライト、カメラ、またはその他の表示可能なコンテンツを接続できます
class TagNode: SCNNode {
    
    var data:Dictionary<String,String> = [
        "desk": "作業効率が上がる、スタンディングデスクとは？",
        "bool jacket": "デザイン原則がたくさん隠れています。\n例えば、色の対比です。黒と白という色度/明度/彩度の変化率が大きいほど、見やすいデザインとなります。\nただし多用は厳禁です。",
        "iPod": "",
        "printer": "これはプリンターです。\n現在では３Dプリンタというものも存在し、建築物も作ることができるとか。",
        "electric fan": "扇風機。\n 最新のダイソンの羽のないものは、流体力学のベルヌーイ定理を応用して使われています.",
        "switch": "スイッチ。\n　使いやすさのため、背後にはインタラクションデザインなどがある。\n具体的には、現在電気がついている状態が直感的にわかりやすいよう、\n電気がついている状態は上に存在し、電気が消えている状態は下に存在するスイッチなど.",
        "notebook":"ノート。\nアイデア出しをするときに、ノートの広さとアイデアの質に相関関係が存在する。",
        "nail": "爪。\n 足の爪に塗るペディキュア(pdeicure)の英単語にはpediという部分がある。\nこれには足を表す意味があり、自転車のペダル（pedal）,歩行者(pedestrian)などが良い例です。",
        "rocking chair": "ロッキングチェア。\n 似ているものに、ロッキングベッドがありますが、それを0.25 Hzで10.5 cm横方向に１晩中動かしました。\nすると、深いノンレム睡眠に入るまでに要する時間が短くなることが判明しました。",
        "grass": "草。\n　非常に草ですね",
        "tree": "木。\n針葉樹と広葉樹がある。",
        "stone": "石。\n　蹴って使います。",
        "rock": "岩。\nこれは岩です。ここに情報が追加されます。",
        "ball":"ボール。\n４号球〜６号くらいが一般的。",
        "shoes":"靴。\n "
    ]

    //ここに外部から識別情報が付与される
    var classificationObservation: VNClassificationObservation? {
        didSet {
            addTextNode()
        }
    }
    
    private func addTextNode() {
        //textは識別結果(identifier)が,で区切られて出ているっぽい　cat,dog,something...
        guard let text = classificationObservation?.identifier else {return}
        let shorten = text.components(separatedBy: ", ").first!
        //ここが、テキスト代入される。空間に実際に表示される識別結果
        if let val = self.data[shorten] {
            var textNode = SCNNode.textNode(text: val)
//            var textNode = SCNNode(geometry: text)
            DispatchQueue.main.async(execute: {
                self.addChildNode(textNode)
            })
        }else{
            var textNode = SCNNode.textNode(text: shorten + ":未登録")
            DispatchQueue.main.async(execute: {
                self.addChildNode(textNode)
            })
        }
//        let textNode = SCNNode.textNode(text: "niwa niwa")

        addSphereNode(color: UIColor.green)
    }
    
    private func addSphereNode(color: UIColor) {
        DispatchQueue.main.async(execute: {
            let sphereNode = SCNNode.sphereNode(color: color)
            self.addChildNode(sphereNode)
        })
    }    
}
