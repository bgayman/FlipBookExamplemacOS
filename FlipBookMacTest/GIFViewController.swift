//
//  GIFViewController.swift
//  FlipBookMacTest
//
//  Created by Brad Gayman on 1/31/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import Cocoa

// MARK: - GIFViewController -

final class GIFViewController: NSViewController {
    
    // MARK: - Properties -
    
    var gifURL: URL?
    @IBOutlet weak var shareVisualEffectView: NSVisualEffectView!
    @IBOutlet weak var shareButton: NSButton!
    
    // MARK: - Lifecycle -
    
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
    
    // MARK: - Actions -
    
    @IBAction func share(_ sender: NSButton) {
        guard let url = gifURL else { return }

        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: .zero, of: sender, preferredEdge: .minY)
    }
}
