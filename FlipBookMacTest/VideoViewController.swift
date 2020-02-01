//
//  VideoViewController.swift
//  FlipBookMacTest
//
//  Created by Brad Gayman on 1/31/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import AVKit
import AppKit

// MARK: - VideoViewController -

final class VideoViewController: NSViewController {
    
    // MARK: - Properties -
    
    var videoURL: URL?
    @IBOutlet weak var shareVisualEffectView: NSVisualEffectView!
    @IBOutlet weak var shareButton: NSButton!
    
    // MARK: - Lifecycle -
    
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
    
    // MARK: - Actions -
    
    @IBAction func share(_ sender: NSButton) {
        guard let url = videoURL else { return }

        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: .zero, of: sender, preferredEdge: .minY)
    }
}
