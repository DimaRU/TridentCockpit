/////
////  PastDivesViewController.swift
///   Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import Alamofire
import Kingfisher

class PastDivesViewController: NSViewController {

    let divePreviewItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "divePreviewItemIdentifier")

    // MARK: Outlets
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet var toolbar: NSToolbar!
    @IBOutlet weak var deleteAfterCheckbox: NSButton!
    @IBOutlet weak var noVideoLabel: NSTextField!
    
    private var previewWindowController: NSWindowController?
    
    var sectionDates: [Date] = []
    var recordingBySection: [Date: [Recording]] = [:]
    
    let sectionFormatter = DateFormatter()
    let diveLabelFormatter = DateFormatter()
    let pastDivesWorker = PastDivesWorker()

    #if DEBUG
    deinit {
        print(className, #function)
    }
    #endif
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(named: "splashColor")!.cgColor
        collectionView.enclosingScrollView?.borderType = .noBorder
        collectionView.register(NSNib(nibNamed: "DiveCollectionItem", bundle: nil), forItemWithIdentifier: divePreviewItemIdentifier)
        sectionFormatter.dateFormat = "MMMM dd"
        diveLabelFormatter.dateFormat = "MMM dd hh:mm:ss"
        
        pastDivesWorker.delegate = self
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.toolbar = toolbar
        RecordingsAPI.requestRecordings {
            switch $0 {
            case .success(let data):
                self.sortRecordings(data.recordings)
            case .failure(let error):
                let alert = NSAlert(error: error)
                alert.beginSheetModal(for: NSApp.mainWindow!)
                self.sortRecordings([])
            }
        }
    }
    
    // MARK: Actions
    @IBAction func refreshButtonPress(_ sender: Any) {
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()
        RecordingsAPI.requestRecordings {
            switch $0 {
            case .success(let data):
                self.sortRecordings(data.recordings)
            case .failure(let error):
                let alert = NSAlert(error: error)
                alert.beginSheetModal(for: NSApp.mainWindow!)
                self.sortRecordings([])
            }
        }
    }
    
    @IBAction func selectAllButtonPress(_ sender: Any) {
        collectionView.selectAll(sender)
    }

    @IBAction func deselectAllButtonPress(_ sender: Any) {
        collectionView.deselectAll(sender)
    }

    @IBAction func downloadButtonPress(_ sender: Any) {
        guard !collectionView.selectionIndexPaths.isEmpty else { return }
        let recordings = collectionView.selectionIndexPaths.map { getRecording(by: $0) }
        pastDivesWorker.download(recordings: recordings, deleteAfter: deleteAfterCheckbox.state == .on)
    }

    @IBAction func deleteButtonPress(_ sender: Any) {
        guard !collectionView.selectionIndexPaths.isEmpty else { return }
        let count = collectionView.selectionIndexPaths.count
        let alert = NSAlert()
        alert.messageText = "Delete dive?"
        alert.informativeText = "This will permanently delete \(count) video files on Trident"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let responce = alert.runModal()
        guard responce == .alertFirstButtonReturn else { return }
        let recordings = collectionView.selectionIndexPaths.map { getRecording(by: $0) }
        pastDivesWorker.delete(recordings: recordings)
    }

    @IBAction func goDashboardButtonPress(_ sender: Any) {
        transitionBack(options: .slideRight)
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

    private func previewVideo(recording: Recording) {
        // TODO: Start new video in same window
        guard previewWindowController == nil else { return }
        let storyboard = NSStoryboard(name: .init("PreviewVideoViewController"), bundle: nil)
        guard let windowControler = storyboard.instantiateInitialController() as? NSWindowController,
            let previewVideoViewController = windowControler.contentViewController as? PreviewVideoViewController else { return }
        let panel = windowControler.window! as! NSPanel
        panel.isFloatingPanel = true
        
        previewVideoViewController.videoURL = RecordingsAPI.videoURL(recording: recording)
        previewVideoViewController.videoTitle = "Dive: " + diveLabelFormatter.string(from: recording.startTimestamp)
        
        windowControler.showWindow(nil)
        windowControler.window?.becomeKey()
        windowControler.window?.isMovableByWindowBackground = true
        previewWindowController = windowControler
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(notification:)), name: NSWindow.willCloseNotification, object: windowControler.window)
    }
    
    @objc private func windowWillClose(notification: Notification) {
        guard let object = notification.object as? NSWindow else { return }
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: object)
        previewWindowController = nil
    }
}

// MARK: - NSCollectionViewDataSource
extension PastDivesViewController: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        noVideoLabel.isHidden = !sectionDates.isEmpty
        return sectionDates.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionDate = sectionDates[section]
        return recordingBySection[sectionDate]?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: divePreviewItemIdentifier, for: indexPath) as! DiveCollectionItem
        
        let recording = getRecording(by: indexPath)
        let imageURL = RecordingsAPI.previewURL(recording: recording)
        item.titleLabel.stringValue = diveLabelFormatter.string(from: recording.startTimestamp)
        item.imageView?.kf.indicatorType = .activity
        item.imageView?.kf.setImage(with: imageURL)
        
        item.actionHandler = { [weak self] in
            guard let self = self else { return }
            let recording = self.getRecording(by: indexPath)
            self.previewVideo(recording: recording)
        }
        return item
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        
        let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderView"), for: indexPath) as! HeaderView
        
        let sectionDate = sectionDates[indexPath.section]
        view.label.stringValue = sectionFormatter.string(from: sectionDate)
        return view
    }
}

extension PastDivesViewController: PastDivesProtocol {
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
        collectionView.deselectItems(at: [indexPath])
    }
}
