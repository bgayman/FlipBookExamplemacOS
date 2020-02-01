//
//  ViewController.swift
//  FlipBookMacTest
//
//  Created by Brad Gayman on 1/24/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import Cocoa
import FlipBook
import AVFoundation
import Photos

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
    var shouldCompositeLayerAnimation = false {
        didSet {
            layerContainerView.isHidden = !shouldCompositeLayerAnimation
            layerOverlayView.isHidden = !shouldCompositeLayerAnimation
            containerView.isHidden = shouldCompositeLayerAnimation
        }
    }
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var containerView: NSView!
    var redView: NSView?
    let flipBook = FlipBook()
    @IBOutlet weak var recordViewButton: NSButton!
    @IBOutlet weak var segmentControl: NSSegmentedControl!
    @IBOutlet weak var layerContainerView: NSView!
    @IBOutlet weak var layerOverlayView: NSView!
    
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
        layerContainerView.wantsLayer = true
        layerContainerView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        layerOverlayView.wantsLayer = true
        layerOverlayView.layer?.backgroundColor = NSColor.clear.cgColor
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
        if shouldCompositeLayerAnimation {
            animate(in: layerOverlayView.layer, isForVideo: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + totalAnimationDuration) {
                self.flipBook.stop()
                self.progressIndicator.isHidden = false
            }
        } else {
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
    }
    
    private func animate(in layer: CALayer?, isForVideo: Bool) {
        let system = NSFont.systemFont(ofSize: 30.0, weight: NSFont.Weight.heavy)
        guard let description = system.fontDescriptor.withDesign(.monospaced), let monospaced = NSFont(descriptor: description, size: 30.0) else {
            print("can't make font description")
            return
        }
        
        let paddingHorizontal: CGFloat = 8.0
        let paddingVertical: CGFloat = 4.0
        let attribString = NSAttributedString(string: "DEVELOPERS!", attributes: [.font: monospaced, .foregroundColor: NSColor.textColor])
        let size = attribString.size()
        layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Gradient Layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = layer?.frame ?? .zero
        gradientLayer.colors = [NSColor.textColor.cgColor, NSColor.tertiaryLabelColor.cgColor]
        layer?.addSublayer(gradientLayer)
        
        // Text Layer
        let tLayer = CATextLayer()
        tLayer.string = attribString
        tLayer.frame = CGRect(origin: CGPoint(x: 0.0, y: paddingVertical * 0.5),
                                size: CGSize(width: size.width, height: size.height + paddingVertical))
        
        // Work around for `CATextLayer` not working with `AVVideoCompositionCoreAnimationTool` https://stackoverflow.com/questions/50901029/avmutablevideocomposition-with-catextlayer-ending-up-with-no-text-string
        let image = snapshot(layer: tLayer, scale: 1.0)
        let textLayer = CALayer()
        textLayer.frame = tLayer.frame
        textLayer.contents = image
        
        // Replicator Layer Horizontal
        let replicatorLayerHorizontal = CAReplicatorLayer()
        replicatorLayerHorizontal.frame = CGRect(origin: .zero,
                                                 size: CGSize(width: layer?.bounds.width ?? 0.0,
                                                              height: size.height + paddingVertical))
        replicatorLayerHorizontal.instanceCount = 30
        replicatorLayerHorizontal.instanceTransform = CATransform3DMakeTranslation(textLayer.bounds.width + paddingHorizontal, 0, 0)
        replicatorLayerHorizontal.addSublayer(textLayer)
        
        // Replicator Layer Vertical
        let replicatorLayerVertical = CAReplicatorLayer()
        replicatorLayerVertical.frame = layer?.bounds ?? .zero
        replicatorLayerVertical.instanceCount = 30
        replicatorLayerVertical.instanceTransform = CATransform3DMakeTranslation(0, textLayer.bounds.height + paddingVertical, 0)
        replicatorLayerVertical.addSublayer(replicatorLayerHorizontal)
        
        gradientLayer.mask = replicatorLayerVertical
        
        // Shape Layer
        let shapeLayerRect = CGRect(origin: .zero,
                                    size: CGSize(width: layer?.bounds.width ?? 0.0,
                                                 height: layer?.bounds.height ?? 0.0))
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = NSColor.black.cgColor
        shapeLayer.frame = shapeLayerRect
        shapeLayer.path = CGPath(rect: shapeLayerRect, transform: nil)
        replicatorLayerVertical.mask = shapeLayer
        
        // Animation
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = CATransform3DMakeTranslation(0.0, layer?.bounds.height ?? 0.0, 0.0)
        animation.toValue = CATransform3DIdentity
        animation.duration = totalAnimationDuration
        if isForVideo {
            animation.beginTime = AVCoreAnimationBeginTimeAtZero
        }
        
        shapeLayer.add(animation, forKey: "animation")
    }
    
    private func startRecording() {
        let sourceView: NSView = shouldCompositeLayerAnimation ? layerContainerView : containerView
        let composition: (CALayer) -> Void = { [weak self] layer in
            self?.animate(in: layer, isForVideo: true)
        }
        
        flipBook.startRecording(sourceView,
                                compositionAnimation: shouldCompositeLayerAnimation ? composition : nil,
                                progress: { [weak self] (prog) in
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
    
    private func snapshot(layer: CALayer, scale: CGFloat) -> NSImage? {
                
        let width = Int(layer.bounds.width * scale)
        let height = Int(layer.bounds.height * scale)
        let imageRepresentation = NSBitmapImageRep(bitmapDataPlanes: nil,
                                                   pixelsWide: width,
                                                   pixelsHigh: height,
                                                   bitsPerSample: 8,
                                                   samplesPerPixel: 4,
                                                   hasAlpha: true,
                                                   isPlanar: false,
                                                   colorSpaceName: NSColorSpaceName.deviceRGB,
                                                   bytesPerRow: 0,
                                                   bitsPerPixel: 0)
        imageRepresentation?.size = CGSize(width: width, height: height)

        guard let imgRep = imageRepresentation,
              let context = NSGraphicsContext(bitmapImageRep: imgRep) else {
            return nil
        }

        layer.render(in: context.cgContext)
        
        let image = NSImage(size: CGSize(width: width, height: height))
        image.addRepresentation(imgRep)
        return image
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
    
    @IBAction func switchLayerAnimation(_ sender: NSSwitch) {
        shouldCompositeLayerAnimation = sender.state == .on
    }
    
}

