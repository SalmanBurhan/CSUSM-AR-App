//
//  CatalogARView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/1/23.
//

import ARKit
import Combine
import SwiftUI

/// A SwiftUI view that displays a catalog of locations in augmented reality.
///
/// Use this view to present a catalog of locations in an augmented reality experience. The view provides a visual representation of the locations using augmented reality technology.
struct CatalogARView: View {

  // MARK: - PROPERTIES

  /// A set of subscriptions to Combine publishers.
  private var cancellables: Set<AnyCancellable> = []

  /// The AR session manager for the catalog AR experience.
  private var session = CatalogARSessionManager.shared

  /// A boolean value indicating whether the user has granted location permissions to the app.
  @State private var hasLocationPermissions = false

  /// A boolean value indicating whether Visual Positioning System (VPS) is currently available.
  @State private var isVPSAvailable = false

  /// The statistics of the AR session.
  @State private var sessionStatistics: CatalogARSessionStatistics?

  /**
     Initializes a CatalogARView with the given locations and category.

     - Parameters:
        - locations: An array of Concept3DLocation objects representing the catalog locations.
        - category: A Concept3DCategory object representing the category of the catalog.
     */
  init(_ locations: [Concept3DLocation] = [], category: Concept3DCategory) {
    self.session.catalog = locations
    self.session.category = category
  }

  /**
     The main view for the CatalogAR feature in the app.

     This view displays the augmented reality experience for the locations in the selected category.
     It consists of a VStack that conditionally renders different overlays based on the user's
     location permissions and the availability of Visual Positioning System (VPS).

     If the user has location permissions, the AR session is displayed along with a coaching view,
     a limited VPS view (if VPS is not available), and session statistics (if available).

     If the user does not have location permissions, a view for requesting location authorization is shown.

     The view also subscribes to publishers for changes in location permissions, VPS availability,
     and session statistics, and updates its state accordingly.
    */
  var body: some View {
    VStack {
      if hasLocationPermissions {
        session
          .sceneViewRepresentable
          .overlay(session.coachingViewRepresentable)
          .overlay(isVPSAvailable ? nil : vpsLimitedView())
          .overlay(sessionStatistics != nil ? statisticsView() : nil)
          .onAppear(perform: sceneDidAppear)
          .onDisappear(perform: sceneDidDisappear)
      } else {
        session
          .locationManager
          .viewForAuthorizationStatus()
      }
    }
    .onReceive(session.locationManager.authorizationPublisher) { hasPermissions in
      print(
        "Catalog AR View did receive change in Location Services authorization. | hasPermissions: \(hasPermissions)"
      )
      self.hasLocationPermissions = hasPermissions
    }
    .onReceive(session.vpsPublisher) { isAvailable in
      print("Catalog AR View did receive change in VPS availability. | isAvailable: \(isAvailable)")
      self.isVPSAvailable = isAvailable
    }
    .onReceive(session.statisticsPublisher) { statistics in
      self.sessionStatistics = statistics
    }
  }

  /// This method is called when the scene view appears.
  func sceneDidAppear() {
    print("SceneView did appear")
    session.run()
  }

  /// This method is called when the scene view disappears.
  func sceneDidDisappear() {
    print("SceneView did disappear")
    session.pause()
  }

  /**
     A view that displays a message indicating that Visual Positioning (VPS)
     is unavailable and the app is relying solely on GPS data.

     - Returns: A SwiftUI view that displays the VPS limited message.
    */
  @ViewBuilder
  func vpsLimitedView() -> some View {
    VStack {
      Text("Visual Positioning (VPS) unavailable. Relying solely on GPS data.")
        .font(.caption)
        .opacity(0.8)
      Spacer()
    }
  }

  /**
     A view that displays the statistics of the AR session.

     This view shows the location accuracy, altitude accuracy, and orientation accuracy of the AR session.
     If there is an error, it displays the error message.

     - Returns: A SwiftUI view that displays the AR session statistics.
     */
  @ViewBuilder
  func statisticsView() -> some View {
    if let statistics = self.sessionStatistics {
      VStack {
        Spacer()
        HStack {
          if statistics.error {
            Text(statistics.errorMessageString)
              .font(.caption2).multilineTextAlignment(.center).opacity(0.8)
          } else {
            Text(statistics.locationAccuracyString)
              .font(.caption2).multilineTextAlignment(.center).opacity(0.8)
            Spacer()
            Text(statistics.altitudeAccuracyString)
              .font(.caption2).multilineTextAlignment(.center).opacity(0.8)
            Spacer()
            Text(statistics.orientationAccuracyString)
              .font(.caption2).multilineTextAlignment(.center).opacity(0.8)
          }
        }.padding([.leading, .trailing], 5)
      }
    } else {
      EmptyView()
    }
  }
}
