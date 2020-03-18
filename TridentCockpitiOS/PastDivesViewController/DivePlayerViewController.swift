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
