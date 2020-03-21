/////
////  Error+alerts.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import Alamofire

extension UIAlertController {
    func presentOntop() {
        let window = UIApplication.shared.windows.first{ $0.isKeyWindow }
        var controller = window?.rootViewController
        if let navController = controller as? UINavigationController {
            controller = navController.presentedViewController
        }
        
        if let popoverController = self.popoverPresentationController, let view = controller?.view {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        controller?.present(self, animated: true)
    }
}

func alert(message: String, informative: String? = nil, delay: Int = 5) {
    let alertController = UIAlertController(title: message,
                                            message: informative,
                                            preferredStyle: .actionSheet)
    let action = UIAlertAction(title: "Dismiss", style: .cancel)
    alertController.addAction(action)
    alertController.presentOntop()

    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) { [weak alertController] in
        guard let alertController = alertController else { return }
        alertController.dismiss(animated: true)
    }
}

extension Error {
    func alert(delay: Int = 4) {
        let alertController = UIAlertController(title: self.localizedDescription,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        if let error = self as? NetworkError {
            alertController.message = error.message()
        }
        
        if let error = self as? AFError,
            case AFError.sessionTaskFailed = error,
            let underlying = error.underlyingError {
            alertController.title = underlying.localizedDescription
        }
        
        let action = UIAlertAction(title: "Dismiss", style: .cancel)
        alertController.addAction(action)
        alertController.presentOntop()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) { [weak alertController] in
            guard let alertController = alertController else { return }
            alertController.dismiss(animated: true)
        }
    }

}
