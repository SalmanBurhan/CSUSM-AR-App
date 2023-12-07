//
//  LocationNodeUIView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/6/23.
//

import UIKit
import ARKit

class LocationNodeUIView: UIView {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var locationNameLabel: UILabel!
    @IBOutlet var locationCategoryLabel: UILabel!
    @IBOutlet var locationDistanceLabel: UILabel!
    @IBOutlet var containerView: UIView!
    
    let strokeWidth: CGFloat = 5.0
    let strokeColor: UIColor = UIColor.tintColor

    // MARK: - Initialization

    /// Width in meters
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 556, height: 160))
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        // Load the XIB file
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
        nib.instantiate(withOwner: self, options: nil)
        addSubview(containerView)
        self.addConstraints()

        self.containerView.layer.isOpaque = false
        self.layer.backgroundColor = UIColor.clear.cgColor
        self.layer.isOpaque = false

        self.containerView.isOpaque = false
        self.containerView.backgroundColor = .clear
        self.backgroundColor = UIColor.white.withAlphaComponent(0.70)
        self.isOpaque = false
    }
    
    private func addConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        // Set the content hugging and compression resistance priorities
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }
    
    func configure(name: String, category: String, categoryImageURL: URL?, distance: Float) {
        DispatchQueue.main.async {
            self.locationNameLabel.text = name
            self.locationCategoryLabel.text = category
            self.locationDistanceLabel.text = String(format: "%0.0f Feet", distance)
            self.imageView.image = UIImage(named: "building-circle-filled")
        }
        if let imageURL = categoryImageURL {
            //self.downloadImage(from: imageURL)
        }
    }
    
    func configure(distance: Float) {
        DispatchQueue.main.async {
            self.locationDistanceLabel.text = String(format: "%0.0f Feet", distance)
        }
    }
    
    func downloadImage(from url: URL) {
        print("Downloading node icon from url: \(url)")
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                // Handle error
                print("Error loading image from url: \(url)")
                return
            }

            DispatchQueue.main.async {
                if let image = UIImage(data: data) {
                    self.imageView.image = image
                }
            }

        }.resume()
    }

    
//    func asTextureMaterial() -> SCNMaterial {
//        let renderer = UIGraphicsImageRenderer(size: containerView.bounds.size)
//        
//        let image = renderer.image { _ in
//            containerView.drawHierarchy(in: containerView.bounds, afterScreenUpdates: true)
//        }
//        
//        // Create an SCNMaterial with the UIImage
//        let material = SCNMaterial()
//        material.diffuse.contents = image
//
//        return material
//    }

    // MARK: - Intrinsic Content Size

    override var intrinsicContentSize: CGSize {
        // Calculate and return the intrinsic content size based on your content
        return CGSize(width: 556, height: 160)
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Calculate the inner rect for the stroke
        let innerRect = bounds.insetBy(dx: 10, dy: 10)

        // Get the current graphics context
        if let context = UIGraphicsGetCurrentContext() {
            // Set stroke color and width
            context.setStrokeColor(strokeColor.cgColor)
            context.setLineWidth(strokeWidth)
            
            // Draw the inner stroke
            context.stroke(innerRect)
        }
        
        // Create a blur effect
        let blurEffect = UIBlurEffect(style: .light) // You can change the style as needed
        // Create a visual effect view with the blur effect
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(visualEffectView, at: 0)

    }

}
