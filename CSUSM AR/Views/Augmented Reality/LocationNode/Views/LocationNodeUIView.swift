//
//  LocationNodeUIView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/6/23.
//

import UIKit
import ARKit

class LocationNodeUIView: UIView {

    // MARK: - IBOutlets

    /// The image view for the location category.
    @IBOutlet var imageView: UIImageView!

    /// The label for the location name.
    @IBOutlet var locationNameLabel: UILabel!
    
    /// The label for the location category.
    @IBOutlet var locationCategoryLabel: UILabel!
    
    /// The label for the location distance.
    @IBOutlet var locationDistanceLabel: UILabel!
    
    /// The container view for the location node.
    /// This is the root view of the XIB file.
    @IBOutlet var containerView: UIView!
    
    // MARK: - Properties

    /// The width of the stroke around the view.
    let strokeWidth: CGFloat = 5.0
    /// The color of the stroke around the insets of the view.
    let strokeColor: UIColor = UIColor.tintColor

    // MARK: - Initialization

    /// Initializes a LocationNodeUIView with the default frame size.
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 556, height: 160))
        commonInit()
    }
    
    /// Initializes a LocationNodeUIView with the given frame size.
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    /// Initializes a LocationNodeUIView with the given decoder.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    // MARK: - Common Initialization

    /// Performs common initialization tasks for the view.
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

    // MARK: - Constraints

    /// Adds the constraints for the view.
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
    
    // MARK: - Configuration

    /// Configures the view with the given location information.
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
    
    /// Configures the distance label of the view with the given location distance.
    func configure(distance: Float) {
        DispatchQueue.main.async {
            self.locationDistanceLabel.text = String(format: "%0.0f Feet", distance)
        }
    }
    
    /// Downloads the image from the given URL and sets it to the image view.
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

    /// Returns the intrinsic content size for the view.
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 556, height: 160)
    }

    /// Draws the view. This is where the stroke is drawn.
    /// 
    /// - Parameter rect: The portion of the view that needs to be redrawn.
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
        // Set the frame of the visual effect view to the bounds of the view
        visualEffectView.frame = bounds
        // Set the autoresizing mask so that the visual effect view will always fill the view
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Add the visual effect view to the view
        insertSubview(visualEffectView, at: 0)

    }

}
