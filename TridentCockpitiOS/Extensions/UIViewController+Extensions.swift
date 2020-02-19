/////
////  UIViewControllerExtensions.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(error: Error, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: error.localizedDescription,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "Dismiss", style: .default) { _ in
            completion?()
        }
        alertController.addAction(action)
        self.present(alertController, animated: true)
    }

    func alert(message: String, informative: String, delay: Int = 5) {
        let alertController = UIAlertController(title: message,
                                                message: informative,
                                                preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "Dismiss", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) { [weak alertController] in
            guard let alertController = alertController else { return }
            alertController.dismiss(animated: true)
        }
    }
    
    func alert(error: Error, delay: Int = 4) {
        let alertController = UIAlertController(title: error.localizedDescription,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        if let error = error as? NetworkError {
            alertController.message = error.message()
        }
        let action = UIAlertAction(title: "Dismiss", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) { [weak alertController] in
            guard let alertController = alertController else { return }
            alertController.dismiss(animated: true)
        }
    }

}

extension UIViewController {
    func present(_ viewControllerToPresent: UIViewController, options: CATransitionSubtype) {
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.moveIn
        transition.subtype = options
        self.view.window!.layer.add(transition, forKey: kCATransition)

        present(viewControllerToPresent, animated: false)
    }

    func dismiss(options: CATransitionSubtype) {
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = CATransitionType.reveal
        transition.subtype = options
        self.view.window!.layer.add(transition, forKey: kCATransition)

        dismiss(animated: false)
    }
}
