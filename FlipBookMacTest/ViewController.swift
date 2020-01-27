//
//  ViewController.swift
//  FlipBookMacTest
//
//  Created by Brad Gayman on 1/24/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import Cocoa
import FlipBook
import AVKit
import PhotosUI

// MARK: - ViewController -

let totalAnimationDuration: TimeInterval = 6.0

final class ViewController: NSViewController {
    
    // MARK: - Types -
    
    enum Segment: Int {
        case video
        case livePhoto
        case gif
    }
    
    // MARK: - Properties -
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var containerView: NSView!
    var redView: NSView?
    let flipBook = FlipBook()
    @IBOutlet weak var recordViewButton: NSButton!
    @IBOutlet weak var segmentControl: NSSegmentedControl!
    
    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let rView = NSView(frame: NSRect(origin: CGPoint(x: 10, y: 50),
                                         size: CGSize(width: 100, height: 100)))
        rView.wantsLayer = true
        rView.layer?.backgroundColor = NSColor.systemRed.cgColor
        containerView.addSubview(rView)
        redView = rView
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        recordViewButton.wantsLayer = true
        recordViewButton.layer?.backgroundColor = NSColor.systemRed.cgColor
        recordViewButton.layer?.cornerRadius = 4.0
        recordViewButton.layer?.masksToBounds = true
        segmentControl.selectedSegment = 0
        flipBook.assetType = .video
        flipBook.preferredFramesPerSecond = 60
        title = "FlipBook"
    }
    
    // MARK: - Segue -
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "video":
            guard let videoVC = segue.destinationController as? VideoViewController else {
                return
            }
            videoVC.videoURL = sender as? URL
        case "livephoto":
            guard let livePhotoVC = segue.destinationController as? LivePhotoViewController, let dict = sender as? [String: Any] else {
                return
            }
            livePhotoVC.livePhoto = dict["livePhoto"] as? PHLivePhoto
            livePhotoVC.livePhotoResources = dict["resources"] as? LivePhotoResources
        case "gif":
            guard let gifVC = segue.destinationController as? GIFViewController else {
                return
            }
            gifVC.gifURL = sender as? URL
        default:
            break
        }
    }
    
    // MARK: - Private Methods -

    private func handle(_ asset: FlipBookAssetWriter.Asset) {
        switch asset {
        case .video(let url):
            performSegue(withIdentifier: "video", sender: url)
        case let .livePhoto(livePhoto, resources):
            performSegue(withIdentifier: "livephoto", sender: ["livePhoto": livePhoto, "resources": resources])
        case .gif(let url):
            performSegue(withIdentifier: "gif", sender: url)
        }
    }
    
    private func animateRedView() {
        let frame = redView?.frame ?? .zero
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = totalAnimationDuration * 0.5
            self.redView?.animator().frame = NSRect(origin: CGPoint(x: self.view.frame.maxX - self.view.frame.height, y: 0.0), size: CGSize(width: self.view.frame.height, height: self.view.frame.height))
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = totalAnimationDuration * 0.5
                self.redView?.animator().frame = frame
            }, completionHandler: {
                self.flipBook.stop()
                self.progressIndicator.isHidden = false
            })
        })
    }
    
    private func startRecording() {
        flipBook.startRecording(containerView, progress: { [weak self] (prog) in
            print(prog)
            self?.progressIndicator.doubleValue = Double(prog)
        }, completion: { [weak self] result in
            guard let self = self else {
                return
            }
            self.progressIndicator.isHidden = true
            self.progressIndicator.doubleValue = 0.0
            self.recordViewButton.isEnabled = true
            switch result {
            case .success(let asset):
                self.handle(asset)
            case .failure(let error):
                print(error)
            }
        })
    }
    
    // MARK: - Actions -
    
    @IBAction private func recordView(_ sender: NSButton) {
        sender.isEnabled = false
        startRecording()
        animateRedView()
    }
    
    
    @IBAction func changeSegment(_ sender: NSSegmentedControl) {
        guard let segment = Segment(rawValue: sender.selectedSegment) else {
            return
        }
        switch segment {
        case .video:
            flipBook.assetType = .video
            flipBook.preferredFramesPerSecond = 60
        case .livePhoto:
            flipBook.assetType = .livePhoto(nil)
            flipBook.preferredFramesPerSecond = 60
        case .gif:
            flipBook.assetType = .gif
            flipBook.preferredFramesPerSecond = 12
        }
    }
}

// MARK: - VideoViewController -

final class VideoViewController: NSViewController {
    
    var videoURL: URL?
    @IBOutlet weak var shareVisualEffectView: NSVisualEffectView!
    @IBOutlet weak var shareButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video"
        guard let url = videoURL else { return }
        let avPV = AVPlayerView(frame: self.view.bounds)
        avPV.player = AVPlayer(url: url)
        view.addSubview(avPV, positioned: .below, relativeTo: shareVisualEffectView)
        
        shareVisualEffectView.wantsLayer = true
        shareVisualEffectView.layer?.cornerRadius = 8.0
        shareVisualEffectView.layer?.masksToBounds = true
    }
    
    @IBAction func share(_ sender: NSButton) {
        guard let url = videoURL else { return }

        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: .zero, of: sender, preferredEdge: .minY)
    }
}

// MARK: - LivePhotoViewController -

final class LivePhotoViewController: NSViewController {
    
    var livePhoto: PHLivePhoto?
    var livePhotoResources: LivePhotoResources?
    @IBOutlet weak var shareVisualEffectView: NSVisualEffectView!
    @IBOutlet weak var shareButton: NSButton!
    let livePhotoWriter = FlipBookLivePhotoWriter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live Photo"
        
        let livePhotoView = PHLivePhotoView(frame: view.bounds)
        livePhotoView.livePhoto = livePhoto
        
        view.addSubview(livePhotoView, positioned: .below, relativeTo: shareVisualEffectView)
        
        shareVisualEffectView.wantsLayer = true
        shareVisualEffectView.layer?.cornerRadius = 8.0
        shareVisualEffectView.layer?.masksToBounds = true
    }
    
    @IBAction func share(_ sender: NSButton) {
        guard let resources = livePhotoResources else {
            return
        }
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
            guard let self = self else {
                return
            }
            switch status {
            case .notDetermined, .restricted, .denied:
                break
            case .authorized:
                self.livePhotoWriter.saveToLibrary(resources) { (result) in
                    switch result {
                    case .success(let success):
                        print("Saved to photo library: \(success)")
                    case .failure(let error):
                        print(error)
                    }
                }
            @unknown default:
                break
            }
        }
    }
}

// MARK: - GIFViewController -

final class GIFViewController: NSViewController {
    
    var gifURL: URL?
    @IBOutlet weak var shareVisualEffectView: NSVisualEffectView!
    @IBOutlet weak var shareButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "GIF"
        
        let imageView = NSImageView(frame: view.bounds)
        imageView.animates = true
        
        view.addSubview(imageView, positioned: .below, relativeTo: shareVisualEffectView)
        
        shareVisualEffectView.wantsLayer = true
        shareVisualEffectView.layer?.cornerRadius = 8.0
        shareVisualEffectView.layer?.masksToBounds = true
        
        guard let url = gifURL else {
            return
        }
        imageView.image = NSImage(contentsOf: url)
    }
    
    @IBAction func share(_ sender: NSButton) {
        guard let url = gifURL else { return }

        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: .zero, of: sender, preferredEdge: .minY)
    }
}

