/////
////  RovModelView.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import SceneKit

class RovModelView: SCNView, FloatingViewProtocol {
    weak var xConstraint: NSLayoutConstraint?
    weak var yConstraint: NSLayoutConstraint?

    var mousePosRelatedToView: CGPoint?
    var isDragging: Bool = false
    var cpv: CGFloat = 0
    var cph: CGFloat = 0
    let alignConst: CGFloat = -1
    var isAlignFeedbackSent = false

    override func awakeFromNib() {
        super.awakeFromNib()
        self.roundCorners(withRadius: 6)
        initScene()
    }
    
    private func initScene() {
        guard let scene = SCNScene(named: "TridentCockpit.scnassets/trident.scn") else {
            fatalError("No scene file")
        }
        allowsCameraControl = false
        autoenablesDefaultLighting = true
        cameraControlConfiguration.allowsTranslation = false
        self.scene = scene
        let node = modelNode()
        node.pivot = SCNMatrix4MakeRotation(.pi, 0, 0, 1)
        setCameraPos(yaw: .pi)
    }

    func setCameraPos(yaw: Float) {
        let distance: Float = 100
        let cz: Float = distance * cos(yaw)
        let cx: Float = distance * sin(yaw)
        let cy: Float = distance * sin(15.0 / 180 * .pi)
        let camera = pointOfView!
        camera.simdPosition = simd_float3(x: cx, y: cy, z: cz)
        camera.simdLook(at: simd_float3(x: 0, y: 0, z: 0),
                        up: SCNNode.simdLocalUp,
                        localFront: SCNNode.simdLocalFront)
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownAct(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        mouseDraggedAct(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        mouseUpAct(with: event)
    }
    
    func savePosition(cph: CGFloat, cpv: CGFloat) {
        Preference.rovModelViewCPH = cph
        Preference.rovModelViewCPV = cpv
    }
    
    func loadPosition() -> (cph: CGFloat?, cpv: CGFloat?) {
        return (
            Preference.rovModelViewCPH,
            Preference.rovModelViewCPV
        )
    }
    
    func modelNode() -> SCNNode {
        self.scene!.rootNode.childNode(withName: "trident", recursively: true)!
    }
    
}
