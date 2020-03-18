/////
////  DivePlayerViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import AVKit

final class DivePlayerViewController: AVPlayerViewController {

    static var shared: DivePlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func removeFromContainer() {
        guard parent != nil else { return }
        player?.pause()
        player = nil

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
        DivePlayerViewController.shared = nil
    }
    
    // Thanks to https://stackoverflow.com/a/36853320/7666732
    func enterFullscreen() {
        let name: String
        
        if #available(iOS 11.3, *) {
            name = "_transitionToFullScreenAnimated:interactive:completionHandler:"
        } else {
            name = "_transitionToFullScreenViewControllerAnimated:completionHandler:"
        }
        
        let selectorToForceFullScreenMode = NSSelectorFromString(name)
        if responds(to: selectorToForceFullScreenMode) {
            perform(selectorToForceFullScreenMode, with: true, with: nil)
        }
    }


    class func add(to view: UIView, parentViewController: UIViewController) -> DivePlayerViewController {
        let viewController = DivePlayerViewController()
        DivePlayerViewController.shared = viewController
        parentViewController.addChild(viewController)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(viewController.view, at: view.subviews.count - 1)
        viewController.didMove(toParent: parentViewController)
        return viewController
    }

}
