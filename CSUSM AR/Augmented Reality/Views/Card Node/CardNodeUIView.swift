//
//  CardNodeUIView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/29/23.
//

import Foundation
import UIKit

class CardNodeUIView: UIView {

    let width: CGFloat = 1463.0
    let height: CGFloat = 427.0
        
    var textLabelWidth: CGFloat {
        return 0.70 * self.width
    }
    
    var imageViewWidth: CGFloat {
        return 0.30 * self.width
    }
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        let paddingPercentage: CGFloat = 0.05
        let availableWidth = self.textLabelWidth * (1 - paddingPercentage * 2) /// Subtracting padding from both sides
        var fontSize: CGFloat = 80.0
        label.frame = CGRectMake(0, 0, self.width - self.imageViewWidth, self.height)
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.5
        label.textColor = .black
        label.textAlignment = .center
        label.backgroundColor = UIColor.white
        label.text = self.name
        while true {
            label.font = UIFont.systemFont(ofSize: fontSize, weight: .heavy)
            let textWidth = label.intrinsicContentSize.width
            if textWidth <= availableWidth { break }
            fontSize -= 1
            if fontSize < 1 { break } /// Font size is too small, break to avoid an infinite loop.
        }
        return label
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "building-circle-filled"))
        imageView.frame = CGRectMake(self.width - self.imageViewWidth, 0, self.imageViewWidth, self.height)
        imageView.backgroundColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let name: String
    
    init(text: String) {
        self.name = text
        super.init(frame: CGRectMake(0, 0, self.width, self.height))
        DispatchQueue.main.async {
            self.isOpaque = false
            self.addSubview(self.textLabel)
            self.addSubview(self.imageView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
