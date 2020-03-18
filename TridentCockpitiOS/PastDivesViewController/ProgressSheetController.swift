/////
////  ProgressSheetController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit

class ProgressSheetController: UIViewController {

    @IBOutlet weak var appImageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileCountLabel: UILabel!
    @IBOutlet weak var fileProgressView: LinearProgressBar!
    @IBOutlet weak var totalProgressView: LinearProgressBar!
    var delegate: (()->Void)?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        preferredContentSize = view.bounds.size
        modalPresentationStyle = .formSheet
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = view.bounds.size
        modalPresentationStyle = .formSheet
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let appImageName = getHighResolutionAppIconName() else { return }
        appImageView.image = UIImage(named: appImageName)
    }

    @IBAction func cancelButtonTap(_ sender: Any) {
        delegate?()
    }

    // Thanks Alberto Malagoli https://stackoverflow.com/a/53651051/7666732
    private func getHighResolutionAppIconName() -> String? {
        guard let infoPlist = Bundle.main.infoDictionary else { return nil }
        guard let bundleIcons = infoPlist["CFBundleIcons"] as? NSDictionary else { return nil }
        guard let bundlePrimaryIcon = bundleIcons["CFBundlePrimaryIcon"] as? NSDictionary else { return nil }
        guard let bundleIconFiles = bundlePrimaryIcon["CFBundleIconFiles"] as? NSArray else { return nil }
        guard let appIcon = bundleIconFiles.lastObject as? String else { return nil }
        return appIcon
    }
}
