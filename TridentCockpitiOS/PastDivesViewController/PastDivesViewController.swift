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
    @IBOutlet weak var deleteAfterSwitch: PWSwitch!
    
    var sectionDates: [Date] = []
    var recordingBySection: [Date: [Recording]] = [:]
    var downloadState: [String: SmartDownloadButton.DownloadState] = [:]
    var progressState: [String: Double] = [:]
    
    let sectionFormatter = DateFormatter()
    let diveLabelFormatter = DateFormatter()
    weak var recordingsAPI: RecordingsAPI! = RecordingsAPI.shared

    override func viewDidLoad() {
        super.viewDidLoad()
//        KingfisherManager.shared.cache.clearDiskCache()
        KingfisherManager.shared.downloader.sessionConfiguration.httpMaximumConnectionsPerHost = 1
        KingfisherManager.shared.downloader.sessionConfiguration.waitsForConnectivity = false
        
        recordingsAPI?.setup(remoteAddress: FastRTPS.remoteAddress, delegate: self)
        
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

        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name:UIDevice.orientationDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                DivePlayerViewController.shared?.removeFromContainer()
            }
        }
        NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: nil, queue: nil) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                DivePlayerViewController.shared?.removeFromContainer()
            }
        }

        
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshRecordings), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        refreshRecordings()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        KingfisherManager.shared.cache.clearMemoryCache()
    }
    
    @objc func deviceRotated() {
        setupLayout(for: view.bounds.size)
        collectionView.setNeedsLayout()
    }
    
    @objc func refreshRecordings() {
        recordingsAPI.requestRecordings { result in
            switch result {
            case .success(let recordings):
                self.collectionView.refreshControl?.endRefreshing()
                self.sortRecordings(recordings)
            case .failure(let error):
                self.collectionView.refreshControl?.endRefreshing()
                error.alert(delay: 100)
                self.sortRecordings([])
            }
        }
    }
    
    //MARK: Overrides
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FastRTPS.registerReader(topic: .rovRecordingStats) { [weak self] (recordingStats: RovRecordingStats) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let availableBytes = recordingStats.diskSpaceTotalBytes < recordingStats.diskSpaceUsedBytes ? 0 : recordingStats.diskSpaceTotalBytes - recordingStats.diskSpaceUsedBytes
                let level = Double(availableBytes) / Double(recordingStats.diskSpaceTotalBytes)
                let gigabyte: Double = 1000 * 1000 * 1000
                let total = Double(recordingStats.diskSpaceTotalBytes) / gigabyte
                let availableGB = Double(availableBytes) / gigabyte
                self.availableSpaceLabel.text = String(format: "%.1f GB of %.1f GB free", availableGB, total)
                
                self.availableSpaceBar.progressValue = CGFloat(level) * 100
                self.availableSpaceBar.transform = CGAffineTransform(rotationAngle: .pi)
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

    // MARK: Action
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
        let recordings = selected.map { getRecording(by: $0) }.filter{ downloadState[$0.sessionId]! == .start }
        download(recordings: recordings)
    }
    
    @IBAction func deleteButtonTap(_ sender: Any) {
        guard let selected = collectionView.indexPathsForSelectedItems, !selected.isEmpty else { return }
        let count = selected.count
        let sheet = UIAlertController(title: "This will permanently delete \(count) video files on Trident",
            message: "Delete dive?",
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            let recordings = selected.map { self.getRecording(by: $0) }
            self.delete(recordins: recordings)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        sheet.addAction(okAction)
        sheet.addAction(cancelAction)
        present(sheet, animated: true)
    }
    
    @IBAction func cancelButtonTap(_ sender: Any) {
        let count = downloadState.values.filter{ $0 == .wait || $0 == .run }.count
        guard count != 0 else { return }
        let sheet = UIAlertController(title: "Cancel \(count) downloads?",
            message: "Are you sure?",
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.recordingsAPI.cancelDownloads()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        sheet.addAction(okAction)
        sheet.addAction(cancelAction)
        present(sheet, animated: true)
    }
    
    // MARK: Private functions

    private func download(recordings: [Recording]) {
        for recording in recordings {
            downloadState[recording.sessionId] = .wait
            if let indexPath = getIndexPath(by: recording),
                let item = collectionView.cellForItem(at: indexPath) as? DiveCollectionViewCell {
                item.downloadButton.trasition(to: .wait)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            recordings.forEach{ self.recordingsAPI.download(recording: $0) }
        }
    }

    private func delete(recordins: [Recording]) {
        for recording in recordins {
            recordingsAPI.deleteRecording(with: recording.sessionId) { error in
                if let error = error {
                    error.alert(delay: 10)
                    return
                }
                self.deleteItem(for: recording)
            }
        }
    }
    
    private func deleteItem(for recording: Recording) {
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
    
    private func markItemDownloaded(for recording: Recording) {
        let indexPath = getIndexPath(by: recording)!
        collectionView.deselectItem(at: indexPath, animated: false)
        if let item = collectionView.cellForItem(at: indexPath) as? DiveCollectionViewCell {
            item.downloadButton.trasition(to: .end)
        }
    }

    private func getRecording(by indexPath: IndexPath) -> Recording {
        let sectionDate = sectionDates[indexPath.section]
        return recordingBySection[sectionDate]![indexPath.item]
    }

    private func getRecording(by sessionId: String) -> Recording? {
        for (_, recordings) in recordingBySection {
            if let recording = recordings.first(where: {$0.sessionId == sessionId}) {
                return recording
            }
        }
        return nil
    }

    private func sortRecordings(_ recordings: [Recording]) {
        recordingBySection = [:]
        sectionDates = []
        downloadState = [:]
        for recording in recordings {
            downloadState[recording.sessionId] = .start
            if recordingsAPI.isDownloaded(recording: recording) {
                downloadState[recording.sessionId] = .end
            }
            let date = recording.startTimestamp.clearedTime
            recordingBySection[date, default: []].append(recording)
        }
        
        sectionDates = recordingBySection.keys.sorted(by: > )
        for key in sectionDates {
            recordingBySection[key] = recordingBySection[key]!.sorted(by: {$0.startTimestamp < $1.startTimestamp})
        }
        recordingsAPI.getDownloads { progressList in
            for (sessionId, (countOfBytesReceived, countOfBytesExpectedToReceive)) in progressList {
                let progress: Double
                if countOfBytesReceived == 0 || countOfBytesExpectedToReceive == 0 {
                    progress = 0
                } else {
                    progress = Double(countOfBytesReceived) / Double(countOfBytesExpectedToReceive)
                }
                self.downloadState[sessionId] = progress == 0 ? .wait : .run
                self.progressState[sessionId] = progress
            }
            self.collectionView.reloadData()
        }
    }
    
    private func getIndexPath(by recording: Recording) -> IndexPath? {
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
        DivePlayerViewController.shared?.removeFromContainer()

        let playerViewController = DivePlayerViewController.add(to: cell.subviews[0], parentViewController: self)
        playerViewController.entersFullScreenWhenPlaybackBegins = true
        playerViewController.exitsFullScreenWhenPlaybackEnds = true
        let url = recordingsAPI.videoURL(recording: recording)
        playerViewController.player = AVPlayer(url: url)
        playerViewController.player?.preventsDisplaySleepDuringVideoPlayback = true
        playerViewController.player?.rate = 1
        playerViewController.enterFullscreen()
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
        let imageURL = recordingsAPI.previewURL(recording: recording)
        cell.previewLabel.text = diveLabelFormatter.string(from: recording.startTimestamp)
        cell.previewImage?.kf.indicatorType = .activity
        cell.previewImage?.kf.setImage(with: imageURL)
        cell.downloadButton.downloadState = downloadState[recording.sessionId]!
        cell.downloadButton.progress = progressState[recording.sessionId] ?? 0
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueSupplementaryView(of: DiveCollectionReusableView.self, kind: kind, for: indexPath)
        
        let sectionDate = sectionDates[indexPath.section]
        headerView.headerLabel.text = sectionFormatter.string(from: sectionDate)
        return headerView
    }
}


extension PastDivesViewController: RecordingsAPIProtocol {
    func downloadError(sessionId: String, error: Error) {
        if let recording = getRecording(by: sessionId),
           let indexPath = getIndexPath(by: recording),
           let item = collectionView.cellForItem(at: indexPath) as? DiveCollectionViewCell {
            item.downloadButton.downloadState = .start
        }
        downloadState[sessionId] = .start
        progressState[sessionId] = 0
        let nserror = error as NSError
        if nserror.domain == NSURLErrorDomain,
           nserror.code == NSURLErrorCancelled {
            return
        }
        error.alert(delay: 10)
    }
    
    func downloadEnd(sessionId: String) {
        guard let recording = getRecording(by: sessionId) else { return }
        downloadState[recording.sessionId] = .end
        let deleteAfter = deleteAfterSwitch.on
        if deleteAfter {
            self.delete(recordins: [recording])
        } else {
            self.markItemDownloaded(for: recording)
        }
    }
    
    func progress(sessionId: String, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard
            let recording = getRecording(by: sessionId),
            let indexPath = getIndexPath(by: recording),
            let item = collectionView.cellForItem(at: indexPath) as? DiveCollectionViewCell else { return
        }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        item.downloadButton.downloadState = .run
        item.downloadButton.progress = progress
        downloadState[sessionId] = .run
        progressState[sessionId] = progress
    }
}

extension PastDivesViewController: DiveCollectionViewCellDelegate {
    
    func playButtonAction(cell: DiveCollectionViewCell) {
        guard let path = self.collectionView.indexPath(for: cell) else { return }
        let recording = self.getRecording(by: path)
        self.previewVideo(recording: recording, in: cell)
    }
    
    func downloadButtonAction(cell: DiveCollectionViewCell) {
        guard let path = self.collectionView.indexPath(for: cell) else { return }
        let recording = self.getRecording(by: path)
        self.download(recordings: [recording])
    }
}
