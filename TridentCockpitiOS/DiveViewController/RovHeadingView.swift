/////
////  RovModelView.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import SceneKit

class RovHeadingView: FloatingView {

    override var alignConst: CGFloat { -1 }
    private weak var tridentNode: SCNNode?
    private weak var camera: SCNNode?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.cornerRadius = 10
        let sceneView = SCNView()
        sceneView.frame = bounds
        sceneView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        guard let scene = SCNScene(named: "TridentCockpit.scnassets/trident.scn") else {
            fatalError("No scene file")
        }
        sceneView.backgroundColor = UIColor(named: "cameraControlBackground")!
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.cameraControlConfiguration.allowsTranslation = false
        sceneView.scene = scene
        camera = sceneView.pointOfView
        tridentNode = scene.rootNode.childNode(withName: "trident", recursively: true)
        tridentNode?.pivot = SCNMatrix4MakeRotation(.pi, 0, 0, 1)
        setCameraPos(yaw: .pi)

        addSubview(sceneView)
    }

    func setCameraPos(yaw: Float) {
        let distance: Float = 100
        let cz: Float = distance * cos(yaw)
        let cx: Float = distance * sin(yaw)
        let cy: Float = distance * sin(15.0 / 180 * .pi)
        camera?.simdPosition = simd_float3(x: cx, y: cy, z: cz)
        camera?.simdLook(at: simd_float3(x: 0, y: 0, z: 0),
                        up: SCNNode.simdLocalUp,
                        localFront: SCNNode.simdLocalFront)
    }
    
    func setOrientation(_ orientation: RovQuaternion) {
        tridentNode?.orientation = orientation.scnQuaternion()
    }

    override func loadDefaults() -> CGPoint {
        assert(superview != nil)
        let cph = (superview!.frame.maxX - bounds.midX) / superview!.frame.width
        let cpv = (superview!.frame.maxY - bounds.midY) / superview!.frame.height
        return CGPoint(x: cph, y: cpv)
    }

    override func savePosition(cp: CGPoint) {
        Preference.rovModelViewCPH = cp.x
        Preference.rovModelViewCPV = cp.y
    }

    override func loadPosition() -> CGPoint? {
        guard let cph = Preference.rovModelViewCPH,
              let cpv = Preference.rovModelViewCPV else { return nil }
        return CGPoint(x: cph, y: cpv)
    }

}
