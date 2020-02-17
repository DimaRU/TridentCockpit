/////
////  StoryboardInstantiable.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit

protocol StoryboardInstantiable: AnyObject {
    static func instantiate() -> Self
}
protocol MainStoryboardInstantiable: AnyObject {
    static func instantiate() -> Self
}

extension MainStoryboardInstantiable where Self: UIViewController {
    static func instantiate() -> Self {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let name = String(describing: self)
        return storyboard.instantiateViewController(withIdentifier: name) as! Self
    }
}
extension StoryboardInstantiable where Self: UIViewController {
    static func instantiate() -> Self {
        let name = String(describing: self)
        let storyboard = UIStoryboard.init(name: name, bundle: nil)
        return storyboard.instantiateInitialViewController() as! Self
    }
}
