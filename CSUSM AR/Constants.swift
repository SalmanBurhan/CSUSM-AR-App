//
//  Constants.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 9/22/23.
//

import Foundation
import CoreLocation
import SwiftUI

struct Constants {
    
    struct AR {
        static let kVPS_AVAILABILITY_TEXT = "The Google Visual Positioning Service (VPS) is not available at your current location. Location data may not be as accurate."
        static let kHorizontalAccuracyLowThreshold: CLLocationAccuracy = 10
        static let kHorizontalAccuracyHighThreshold: CLLocationAccuracy = 20
        static let kOrientationYawAccuracyLowThreshold: CLLocationDirectionAccuracy = 15
        static let kOrientationYawAccuracyHighThreshold: CLLocationDirectionAccuracy = 20
        static let kLocalizationFailureTime: TimeInterval = 3 * 60.0
    }
    
    struct Colors {
        static let universityBlue = Color(UIColor(red: 0/255.0, green: 42/255.0, blue: 89/255.0, alpha: 1))
        static let cougarBlue = Color(UIColor(red: 0/255.0, green: 96/255.0, blue: 252/255.0, alpha: 1))
        static let spiritBlue = Color(UIColor(red: 58/255.0, green: 181/255.0, blue: 232/255.0, alpha: 1))
    }
}
