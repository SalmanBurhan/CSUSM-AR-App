//
//  Concept3DLocationImage.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/21/23.
//

import Foundation

/// Enum representing different sizes of Concept3D images.
///
/// - `tiny`: `16:9` Aspect Ratio with `640x360` Resolution.
/// - `small`: `16:9` Aspect Ratio with `854x480` Resolution.
/// - `medium`: `16:9` Aspect Ratio with `1280x720` Resolution.
/// - `large`: `16:9` Aspect Ratio with `1920x1080` Resolution.
/// - `xlarge`: `16:9` Aspect Ratio with `2560x1440` Resolution.
/// - `xxlarge`: `16:9` Aspect Ratio with `3840x2160` Resolution.
enum Concept3DImageSize {

  /// `16:9` Aspect Ratio with `640x360` Resolution.
  case tiny

  /// `16:9` Aspect Ratio with `854x480` Resolution.
  case small

  /// `16:9` Aspect Ratio with `1280x720` Resolution.
  case medium

  /// `16:9` Aspect Ratio with `1920x1080` Resolution.
  case large

  /// `16:9` Aspect Ratio with `2560x1440` Resolution.
  case xlarge

  /// `16:9` Aspect Ratio with `3840x2160` Resolution.
  case xxlarge

  /// Returns the resolution (width and height) of the image size.
  var resolution: (width: Int, height: Int) {
    switch self {
    case .tiny: return (width: 640, height: 360)
    case .small: return (width: 854, height: 480)
    case .medium: return (width: 1280, height: 720)
    case .large: return (width: 1920, height: 1080)
    case .xlarge: return (width: 2560, height: 1440)
    case .xxlarge: return (width: 3840, height: 2160)
    }
  }
}
