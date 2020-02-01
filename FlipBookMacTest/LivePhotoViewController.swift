//
//  LivePhotoViewController.swift
//  FlipBookMacTest
//
//  Created by Brad Gayman on 1/31/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import Cocoa
import PhotosUI
import FlipBook

// MARK: - LivePhotoViewController -

final class LivePhotoViewController: NSViewController {
    
    // MARK: - Properties -
    
    var livePhoto: PHLivePhoto?
    var livePhotoResources: LivePhotoResources?
    @IBOutlet weak var shareVisualEffectView: NSVisualEffectView!
    @IBOutlet weak var shareButton: NSButton!
    let livePhotoWriter = FlipBookLivePhotoWriter()
    
    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live Photo"
        
        let livePhotoView = PHLivePhotoView(frame: view.bounds)
        livePhotoView.livePhoto = livePhoto
        
        view.addSubview(livePhotoView, positioned: .below, relativeTo: shareVisualEffectView)
        
        livePhotoView.translatesAutoresizingMaskIntoConstraints = false
        livePhotoView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        livePhotoView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        livePhotoView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        livePhotoView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        shareVisualEffectView.wantsLayer = true
        shareVisualEffectView.layer?.cornerRadius = 8.0
        shareVisualEffectView.layer?.masksToBounds = true
    }
    
    // MARK: - Actions -
    
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
