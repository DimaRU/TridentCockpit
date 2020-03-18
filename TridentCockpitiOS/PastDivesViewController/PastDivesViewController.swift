/////
////  PastDivesViewController.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import UIKit
import Kingfisher
import AVKit

class PastDivesViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var availableSpaceBar: LinearProgressBar!
    @IBOutlet weak var availableSpaceLabel: UILabel!
    
    var sectionDates: [Date] = []
    var recordingBySection: [Date: [Recording]] = [:]
    
    let sectionFormatter = DateFormatter()
    let diveLabelFormatter = DateFormatter()
    weak var playerViewController: AVPlayerViewController?
    let pastDivesWorker = PastDivesWorker()


    override func viewDidLoad() {
        super.viewDidLoad()
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()
        KingfisherManager.shared.downloader.sessionConfiguration.httpMaximumConnectionsPerHost = 1
        KingfisherManager.shared.downloader.sessionConfiguration.waitsForConnectivity = false
        
        collectionView.allowsMultipleSelection = true
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInsetReference = .fromContentInset

        availableSpaceBar.barColorForValue = { value in
            switch value {
            case 0..<10:
                return UIColor.red
            case 10..<20:
                return UIColor.yellow
            default:
                return UIColor.systemGreen
            }
        }
        
        sectionFormatter.dateFormat = "MMMM dd"
        diveLabelFormatter.dateFormat = "MMM dd hh:mm:ss"
        pastDivesWorker.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name:UIDevice.orientationDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] _ in
            guard let playerViewController = self?.playerViewController else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.removePlayerViewController(playerViewController)
            }
        }

        RecordingsAPI.requestRecordings {
            switch $0 {
            case .success(let data):
                self.sortRecordings(data.recordings)
            case .failure(let error):
                self.alert(error: error, delay: 100)
                self.sortRecordings([])
            }
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func deviceRotated() {
        setupLayout(for: view.bounds.size)
        collectionView.setNeedsLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FastRTPS.registerReader(topic: .rovRecordingStats) { [weak self] (recordingStats: RovRecordingStats) in
            DispatchQueue.main.async {
                let level = Double(recordingStats.diskSpaceTotalBytes - recordingStats.diskSpaceUsedBytes) / Double(recordingStats.diskSpaceTotalBytes)
                let gigabyte: Double = 1000 * 1000 * 1000
                let total = Double(recordingStats.diskSpaceTotalBytes) / gigabyte
                let available = Double(recordingStats.diskSpaceTotalBytes - recordingStats.diskSpaceUsedBytes) / gigabyte
                self?.availableSpaceBar.progressValue = CGFloat(level) * 100
                self?.availableSpaceLabel.text = String(format: "%.1f GB of %.1f GB free", available, total)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        FastRTPS.removeReader(topic: .rovRecordingStats)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupLayout(for: view.bounds.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard collectionView != nil else { return }
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        layout.invalidateLayout()
    }

    @IBAction func selectAllButtonTap(_ sender: Any) {
        for section in sectionDates.indices {
            for item in recordingBySection[sectionDates[section]]!.indices {
                collectionView.selectItem(at: IndexPath(item: item, section: section), animated: false, scrollPosition: [])
            }
        }
    }
    
    @IBAction func deselectAllButtonTap(_ sender: Any) {
        for section in sectionDates.indices {
            for item in recordingBySection[sectionDates[section]]!.indices {
                collectionView.deselectItem(at: IndexPath(item: item, section: section), animated: false)
            }
        }
    }
    
    
    @IBAction func downloadButtonTap(_ sender: Any) {
        guard let selected = collectionView.indexPathsForSelectedItems, !selected.isEmpty else { return }
        let recordings = selected.map { getRecording(by: $0) }
        pastDivesWorker.download(recordings: recordings, deleteAfter: false)
    }
    
    @IBAction func deleteButtonTap(_ sender: Any) {
        guard let selected = collectionView.indexPathsForSelectedItems, !selected.isEmpty else { return }
        let count = selected.count
        let sheet = UIAlertController(title: "This will permanently delete \(count) video files on Trident",
            message: "Delete dive?",
            preferredStyle: .actionSheet)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            let recordings = selected.map { self.getRecording(by: $0) }
            self.pastDivesWorker.delete(recordings: recordings)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        sheet.addAction(okAction)
        sheet.addAction(cancelAction)
    }
    
    
    // MARK: Private functions
    private func getRecording(by indexPath: IndexPath) -> Recording {
        let sectionDate = sectionDates[indexPath.section]
        return recordingBySection[sectionDate]![indexPath.item]
    }
    
    private func sortRecordings(_ recordings: [Recording]) {
        recordingBySection = [:]
        sectionDates = []
        for recording in recordings {
            let date = recording.startTimestamp.clearedTime
            recordingBySection[date, default: []].append(recording)
        }
        
        sectionDates = recordingBySection.keys.sorted(by: > )
        for key in sectionDates {
            recordingBySection[key] = recordingBySection[key]!.sorted(by: {$0.startTimestamp < $1.startTimestamp})
        }
        collectionView.reloadData()
    }
    
    func getIndexPath(by recording: Recording) -> IndexPath? {
        let date = recording.startTimestamp.clearedTime
        guard let section = sectionDates.firstIndex(of: date) else { return nil }
        guard let item = recordingBySection[date]!.firstIndex(where: { $0.startTimestamp == recording.startTimestamp }) else {
            return nil
        }
        return IndexPath(item: item, section: section)
    }

#if targetEnvironment(macCatalyst)
    private func setupLayout(for size: CGSize) {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        let layoutWidth = size.width - layout.sectionInset.left - layout.sectionInset.right
        let itemCount = (layoutWidth / 300).rounded(.down)
        let itemWidth = (layoutWidth + layout.minimumInteritemSpacing) / itemCount - layout.minimumInteritemSpacing
        let itemHeight = itemWidth / 16.0 * 9
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.estimatedItemSize = .zero
        layout.invalidateLayout()
    }
#else
    private func setupLayout(for size: CGSize) {
        guard let orientation = getInterfaceOrientation() else { return }
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = .zero

        switch orientation {
        case .landscapeRight:
            layout.sectionInset.left = collectionView.safeAreaInsets.left != 0 ? collectionView.safeAreaInsets.left : 4
            layout.sectionInset.right = 4
        case .landscapeLeft:
            layout.sectionInset.left = 4
            layout.sectionInset.right = collectionView.safeAreaInsets.right != 0 ? collectionView.safeAreaInsets.right : 4
        default:
            layout.sectionInset.left = 4
            layout.sectionInset.right = 4
            break
        }

        let layoutWidth = size.width - layout.sectionInset.left - layout.sectionInset.right
        let itemWidth: CGFloat
        let itemCount: CGFloat
        if UIDevice.current.userInterfaceIdiom == .pad {
            itemCount = (layoutWidth / 300).rounded(.down)
            itemWidth = (layoutWidth + layout.minimumInteritemSpacing) / itemCount - layout.minimumInteritemSpacing
        } else {
            itemCount = UIScreen.main.traitCollection.verticalSizeClass == .compact ? 2 : 3
            if orientation.isLandscape {
                itemWidth = (layoutWidth + layout.minimumInteritemSpacing) / itemCount - layout.minimumInteritemSpacing
            } else {
                itemWidth = layoutWidth
            }
        }

        let itemHeight = itemWidth / 16.0 * 9
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.estimatedItemSize = .zero
        layout.invalidateLayout()
    }
#endif
    
    private func previewVideo(recording: Recording, in cell: DiveCollectionViewCell) {
        if let playerViewController = playerViewController {
            playerViewController.player?.pause()
            playerViewController.player = nil
            removePlayerViewController(playerViewController)
        }
        
        let playerViewController = addPlayerViewController(to: cell.subviews[0])
        self.playerViewController = playerViewController
        playerViewController.entersFullScreenWhenPlaybackBegins = true
        playerViewController.exitsFullScreenWhenPlaybackEnds = true
        let url = RecordingsAPI.videoURL(recording: recording)
        playerViewController.player = AVPlayer(url: url)
        playerViewController.player?.rate = 1
        enterFullscreen(playerViewController)
    }
    
    private func addPlayerViewController(to view: UIView) -> AVPlayerViewController {
        let viewController = AVPlayerViewController()
        addChild(viewController)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(viewController.view, at: view.subviews.count - 1)
        viewController.didMove(toParent: self)
        return viewController
    }
    
    private func removePlayerViewController(_ viewController: AVPlayerViewController) {
        guard viewController.parent != nil else { return }
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    // Thanks to https://stackoverflow.com/a/36853320/7666732
    private func enterFullscreen(_ playerViewController: AVPlayerViewController) {
        let name: String
        
        if #available(iOS 11.3, *) {
            name = "_transitionToFullScreenAnimated:interactive:completionHandler:"
        } else {
            name = "_transitionToFullScreenViewControllerAnimated:completionHandler:"
        }
        
        let selectorToForceFullScreenMode = NSSelectorFromString(name)
        if playerViewController.responds(to: selectorToForceFullScreenMode) {
            playerViewController.perform(selectorToForceFullScreenMode, with: true, with: nil)
        }
    }
}

extension PastDivesViewController: UICollectionViewDataSource  {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        //        noVideoLabel.isHidden = !sectionDates.isEmpty
        return sectionDates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionDate = sectionDates[section]
        return recordingBySection[sectionDate]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(of: DiveCollectionViewCell.self, for: indexPath)
        
        let recording = getRecording(by: indexPath)
        let imageURL = RecordingsAPI.previewURL(recording: recording)
        cell.previewLabel.text = diveLabelFormatter.string(from: recording.startTimestamp)
        cell.previewImage?.kf.indicatorType = .activity
        cell.previewImage?.kf.setImage(with: imageURL)
        
        cell.actionHandler = { [weak self] in
            guard let self = self else { return }
            let recording = self.getRecording(by: indexPath)
            self.previewVideo(recording: recording, in: cell)
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueSupplementaryView(of: DiveCollectionReusableView.self, kind: kind, for: indexPath)
        
        let sectionDate = sectionDates[indexPath.section]
        headerView.headerLabel.text = sectionFormatter.string(from: sectionDate)
        return headerView
    }
}

extension PastDivesViewController: PastDivesProtocol {
    func presentProgess(sheet: UIViewController) {
        present(sheet, animated: true)
    }
    
    func deleteItem(for recording: Recording) {
        let indexPath = getIndexPath(by: recording)!
        let date = sectionDates[indexPath.section]
        recordingBySection[date]!.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
        if recordingBySection[date]!.isEmpty {
            sectionDates.remove(at: indexPath.section)
            collectionView.deleteSections([indexPath.section])
            if sectionDates.isEmpty {
                collectionView.reloadData()
            }
        }
    }

    func markItemDownloaded(for recording: Recording) {
        let indexPath = getIndexPath(by: recording)!
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}

