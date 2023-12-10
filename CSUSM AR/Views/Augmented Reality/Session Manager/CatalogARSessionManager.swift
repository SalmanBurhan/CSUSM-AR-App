//
//  CatalogARView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/2/23.
//

import Foundation
import ARKit
import ARCoreGeospatial
import ARCoreGARSession
import Combine

/// A manager class responsible for managing the AR session in the catalog view.
class CatalogARSessionManager: NSObject {

    /// The shared instance of the CatalogARSessionManager.
    static let shared = CatalogARSessionManager()

    // MARK: - PROPERTIES
    
    /// The catalog of Concept3DLocations.
    /// - Important: Setting this property will remove all anchors from
    ///              the current AR session.
    var catalog: [Concept3DLocation] {
        didSet {
            self.anchorManager.removeAllAnchors()
        }
    }

    /// The category of Concept3DLocations.
    var category: Concept3DCategory

    /// The `LocationManager` instance used to manage location-related functionality.
    let locationManager: LocationManager

    /// A set of cancellables used to manage subscriptions.
    var cancellables: Set<AnyCancellable>

    /// A publisher that emits a Boolean value indicating whether the Visual
    /// Positioning System feature is available or not.
    let vpsPublisher: CurrentValueSubject<Bool, Never>

    /// A publisher that emits statistics related to the catalog AR session.
    let statisticsPublisher: PassthroughSubject<CatalogARSessionStatistics, Never>
    
    /// The AR session used by the CatalogARSessionManager.
    let session: ARSession

    /// The scene used by the AR session manager.
    let scene: SCNScene
    
    /// The ARSCNView instance used to display the augmented reality scene.
    /// - Important: Use this property to access the `ARSCNView` instance
    ///              instead of directly accessing `sceneViewRepresentable`.
    var sceneView: ARSCNView {
        self.sceneViewRepresentable.unwrappedView
    }
    
    /// The ARCoachingOverlayView used to provide coaching instructions
    /// during an AR session.
    /// - Important: Use this property to access the ARCoachingOverlayView
    ///              view instance instead of directly accessing
    ///              `coachingViewRepresentable`.
    var coachingView: ARCoachingOverlayView {
        self.coachingViewRepresentable.unwrappedView
    }
    
    /// The `GARSession` object used for managing the augmented reality session.
    /// - Note: `GAR` stands for Google Augmented Reality. This is a Google
    ///         library that provides a cross-platform API for ARCore and ARKit.
    var garSession: GARSession?
    /// A boolean value indicating whether anchors have been created.
    var didCreateAnchors: Bool
    /// The current localization state of the AR session manager.
    var localizationState: LocalizationState
    
    /// The low threshold value for horizontal accuracy in meters.
    let kHorizontalAccuracyLowThreshold: CLLocationAccuracy = 10

    /// The high threshold value for horizontal accuracy in meters.
    let kHorizontalAccuracyHighThreshold: CLLocationAccuracy = 20

    /// The low threshold value for orientation yaw accuracy in degrees.
    let kOrientationYawAccuracyLowThreshold: CLLocationDirectionAccuracy = 15

    /// The high threshold value for orientation yaw accuracy in degrees.
    let kOrientationYawAccuracyHighThreshold: CLLocationDirectionAccuracy = 25

    /// The time interval for localization to be deemed as `failure`.
    /// This value is set to 3 minutes (180 seconds).
    let kLocalizationFailureTime: TimeInterval = 3 * 60.0

    /// The date, more importantly the time, when the last localization began.
    var lastBeganLocalizing: Date
    
    /// The session manager responsible for managing the AR session and anchors
    ///  in the catalog AR view.
    /// - Important: The `anchorManager` property is used to manage the
    /// placement and removal of AR anchors.
    let anchorManager: AnchorManager
    
    /// The last error encountered, if any, during the AR session.
    var error: ARSessionError?

    // MARK: - INITALIZERS AND DEINITALIZERS
        
    /**
     Initializes a CatalogARSessionManager with the given locations.
     
     - Parameters:
         - locations: An array of Concept3DLocation objects.
     */
    private init(_ locations: [Concept3DLocation] = []) {
        self.locationManager = LocationManager()
        self.anchorManager = AnchorManager()
        self.category = Concept3DCategory()
        self.lastBeganLocalizing = Date()
        self.session = ARSession()
        self.scene = SCNScene()

        self.vpsPublisher = CurrentValueSubject<Bool, Never>(false)
        self.statisticsPublisher = PassthroughSubject<CatalogARSessionStatistics, Never>()

        self.catalog = locations
        self.didCreateAnchors = false
        self.localizationState = .pretracking
        self.cancellables = []

        super.init()
        self.initializeGARSession()
        self.configureGARSession()

        self.session.delegate = self
        self.subscribeToLocationUpdates()
    }
    
    /// Deinitializes the CatalogARSessionManager.
    deinit {
        print("deinit CatalogARSessionManager")
        self.locationManager.stopMonitoring()
        self.cancellables.forEach({ $0.cancel() })
    }
    
    /// Initializes the GAR (Google ARCore) session.
    fileprivate func initializeGARSession() {
        do {
            self.garSession =  try GARSession(apiKey: Secrets.GoogleAPI.SandboxGoogleAPIKey!, bundleIdentifier: nil)
        } catch let error as GARSessionError {
            self.error = .garSessionError(error)
            self.localizationState = .failed
        } catch {
            self.error = .unexpected(error)
            self.localizationState = .failed
        }
    }

    /// Configures the GAR (Google AR) session.
    fileprivate func configureGARSession() {
        var configurationError: NSError?
        self.garSession?.setConfiguration(self.garSessionConfiguration, error: &configurationError)
        if let configurationError = configurationError {
            self.error = .garSessionError(GARSessionError(_nsError: configurationError))
            self.localizationState = .failed
        } else {
            self.localizationState = .pretracking
        }
    }
    
    /// Subscribes to location updates from `LocationManager` on a 5 second
    /// debounce interval and checks for VPS availability upon receiving a location update.
    fileprivate func subscribeToLocationUpdates() {
        self.cancellables.insert(
            self.locationManager.locationPublisher
                .debounce(for: .seconds(5), scheduler: RunLoop.main).sink {
                    self.garSession?.checkVPSAvailability(coordinate: $0.coordinate) {
                        self.vpsPublisher.send($0 == .available ? true : false) }})
    }
    
    // MARK: - SESSION CONFIGURATIONS

    /// The session configuration used for AR World Tracking.
    let sessionConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.planeDetection = .horizontal
        return configuration
    }()
    
    /// The session configuration used for GAR session.
    let garSessionConfiguration: GARSessionConfiguration = {
        let configuration = GARSessionConfiguration()
        configuration.geospatialMode = .enabled
        configuration.streetscapeGeometryMode = .enabled
        return configuration
    }()

    // MARK: - SWIFT UI VIEWS

    /// A lazy property that represents a wrapped UIView for
    /// the ARCoachingOverlayView.
    ///
    /// This property is used as a SwiftUI representable for integrating
    /// ARCoachingOverlayView into the SwiftUI view hierarchy.
    /// 
    /// - Important: Use `coachingView` to access the ARCoachingOverlayView
    ///              instance instead of directly accessing
    ///              `coachingViewRepresentable`.
    /// - Returns: A wrapped UIView of type ARCoachingOverlayView.
    lazy var coachingViewRepresentable: WrappedUIView<ARCoachingOverlayView> = {
        WrappedUIView<ARCoachingOverlayView>({
            $0.activatesAutomatically = false
            $0.goal = .geoTracking
            $0.session = self.session
        })
    }()
    
    /// A lazy property that represents a wrapped UIView of type ARSCNView.
    /// 
    /// This property is used as a SwiftUI representable for integrating ARSCNView into the SwiftUI view hierarchy.
    /// - Important: Use `sceneView` to access the ARSCNView instance instead of directly accessing `sceneViewRepresentable`.
    /// - Returns: A wrapped UIView of type ARSCNView.
    lazy var sceneViewRepresentable: WrappedUIView<ARSCNView> = {
        WrappedUIView<ARSCNView>({
            $0.session = self.session
            $0.scene = self.scene
            $0.delegate = self
            $0.automaticallyUpdatesLighting = true;
            $0.autoenablesDefaultLighting = true;
            $0.debugOptions = [] //[.showFeaturePoints]
        })
    }()
    
    // MARK: - EXECUTION STATE

    
    /// Runs the AR session and begins monitoring the user's location.
    func run() {
        self.session.run(self.sessionConfiguration, options: [.removeExistingAnchors, .resetTracking])
        self.coachingView.setActive(true, animated: true)
        self.locationManager.startMonitoring()
    }
    
    /// Pauses the AR session and removes all anchors. The user's location is
    /// no longer monitored.
    func pause() {
        self.session.pause()
        self.anchorManager.removeAllAnchors()
        self.locationManager.stopMonitoring()
    }
    
    
    /// This method is called when the localizing process is completed.
    /// It checks if anchors have not been created yet and the AR session is
    /// in the `LocalizationState.tracking` state. If both conditions are met,
    /// it calls the `createAnchors(for:)` method to begin the creasion and
    /// resolving of anchors for the locations in the session's catalog.
    func didCompleteLocalizing() {
        if self.didCreateAnchors == false &&
            self.garSession?.currentFramePair?.garFrame.earth?.trackingState == .tracking {
            self.createAnchors(for: catalog)
        }
    }
    
    // MARK: - STATISTICS

    func __updateLocalizationState() {
        guard let earth = self.garSession?.currentFramePair?.garFrame.earth
        else { self.localizationState = .failed; return }
        switch earth.earthState {
        case .enabled:
            switch earth.trackingState {
            case .tracking: self.localizationState = .localized
            case .paused: self.localizationState = .localizing
            case .stopped: self.localizationState = .failed
            @unknown default: self.localizationState = .failed
            }
        case .errorInternal: self.localizationState = .failed
        case .errorNotAuthorized: self.localizationState = .failed
        case .errorResourceExhausted: self.localizationState = .failed
        @unknown default: self.localizationState = .failed
        }
    }
    
    func _updateLocalizationState() {
        let geospatialTransform = self.garSession?.currentFramePair?.garFrame.earth?.cameraGeospatialTransform
        let now = Date()
        
        if self.garSession?.currentFramePair?.garFrame.earth?.earthState != .enabled {
            self.localizationState = .failed
        }
        
        else if self.garSession?.currentFramePair?.garFrame.earth?.trackingState != .tracking {
            self.localizationState = .pretracking
        }
        
        else {
            if self.localizationState == .pretracking {
                self.localizationState = .localizing
            }
            else if self.localizationState == .localizing {
                if let geospatialTransform = geospatialTransform,
                   geospatialTransform.horizontalAccuracy <= self.kHorizontalAccuracyLowThreshold
                    && geospatialTransform.orientationYawAccuracy <= self.kOrientationYawAccuracyLowThreshold {
                    
                    self.localizationState = .localized
                    print("LOCALIZATION COMPLETE")
                    self.createAnchors(for: catalog)
                    
                }
                else if Date.now.timeIntervalSince(self.lastBeganLocalizing) >= self.kLocalizationFailureTime {
                    self.localizationState = .failed
                }
            }
            else {
                if geospatialTransform == nil {
                    self.localizationState = .localizing
                    self.lastBeganLocalizing = now
                }
                else if let geospatialTransform = geospatialTransform,
                        geospatialTransform.horizontalAccuracy > self.kHorizontalAccuracyHighThreshold
                        || geospatialTransform.orientationYawAccuracy > self.kOrientationYawAccuracyHighThreshold {
                    self.localizationState = .localizing
                    self.lastBeganLocalizing = now
                }
            }
        }
    }


    /**
     Updates the localization state of the AR session manager.
     
     This method is responsible for updating the localization state based on the current frame and earth state of the AR session.

     It checks if the frame and earth objects are available, and if not, sets the localization state to `.pretracking`.
     
     If the earth state is in an error state, the localization state is set to `.failed`.
     
     If the earth state is enabled and the tracking state is not `.tracking`, the localization state is set to `.pretracking`
     
     If the earth state is enabled and the tracking state is `.tracking`, the localization state is updated based on the current
     localization state and the geospatial transform.
     
     If the geospatial transform meets the accuracy thresholds, the localization state is set to `.localized` and additional
     actions are performed.
     
     If the geospatial transform does not meet the accuracy thresholds and the localization failure time has exceeded,
     the localization state is set to `.failed`.
     
     If the geospatial transform is not available or its accuracy exceeds the
     high thresholds, the localization state is set to `.localizing`.
     
     If the earth state is in an unknown state, the localization state is set to `.failed`.
     */
    func updateLocalizationState() {
        guard let frame = self.garSession?.currentFramePair?.garFrame,
              let earth = frame.earth else {
            self.localizationState = .pretracking
            return
        }

        let geospatialTransform = earth.cameraGeospatialTransform
        let now = Date()

        switch earth.earthState {
        case .errorInternal, .errorNotAuthorized, .errorResourceExhausted:
            self.localizationState = .failed
        case .enabled:
            if earth.trackingState != .tracking {
                self.localizationState = .pretracking
            } else {
                switch self.localizationState {
                case .pretracking:
                    self.localizationState = .localizing
                case .localizing:
                    if let geospatialTransform = geospatialTransform,
                       geospatialTransform.horizontalAccuracy <= self.kHorizontalAccuracyLowThreshold,
                       geospatialTransform.orientationYawAccuracy <= self.kOrientationYawAccuracyLowThreshold {
                        self.localizationState = .localized
                        print("LOCALIZATION COMPLETE")
                        self.createAnchors(for: catalog)
                        self.coachingView.setActive(false, animated: true)
                    } else if Date.now.timeIntervalSince(self.lastBeganLocalizing) >= self.kLocalizationFailureTime {
                        self.localizationState = .failed
                    }
                default:
                    self.localizationState = (geospatialTransform == nil ||
                        (geospatialTransform?.horizontalAccuracy ?? 0 > self.kHorizontalAccuracyHighThreshold) ||
                        (geospatialTransform?.orientationYawAccuracy ?? 0 > self.kOrientationYawAccuracyHighThreshold))
                        ? .localizing : .failed
                    self.lastBeganLocalizing = now
                }
            }
        @unknown default:
            self.localizationState = .failed
        }
    }

    
    /**
     Updates the statistics of the AR session.
     
     This method checks the localization state and tracking state of the AR session
     and sends the corresponding statistics to the `statisticsPublisher`. If the
     localization state is failed, an error message indicating localization failure
     is sent. If the tracking state is paused, an error message indicating not
     tracking the environment is sent. Otherwise, the location accuracy, altitude
     accuracy, and orientation accuracy of the camera's geospatial transform are
     sent as statistics.
     */
    func updateStatistics() {
        if self.localizationState == .failed {
            self.statisticsPublisher.send(CatalogARSessionStatistics(errorMessage: "Localization Failed"))
        }
        else if self.garSession?.currentFramePair?.garFrame.earth?.trackingState == .paused {
            self.statisticsPublisher.send(CatalogARSessionStatistics(errorMessage: "Not Tracking Environment"))
        } else if let transform = self.garSession?.currentFramePair?.garFrame.earth?.cameraGeospatialTransform {
            self.statisticsPublisher.send(CatalogARSessionStatistics(
                locationAccuracy: transform.horizontalAccuracy,
                altitudeAccuracy: transform.verticalAccuracy,
                orientationAccuracy: transform.orientationYawAccuracy))
        }
    }
    
    // MARK: - BUILD ANCHORS FROM CATALOG
    
    /**
    Creates anchors for the given locations in combination with the current geospatial transform.
    - Parameters:
        - locations: An array of Concept3DLocation objects representing the locations for which anchors need to be created.
    - Important: You may resolve multiple anchors at a time, but a session cannot be tracking more than
                 100 rooftop or terrain anchors at any given time.
                 Attempting to resolve more will result in `GARSessionErrorCodeResourceExhausted`.
    - Warning: If the geospatial transform in the current GARFrame is invalid, the method will fail to build anchors.
    */
    func createAnchors(for locations: [Concept3DLocation]) {
        print("Creating Anchors for \(locations.count) Locations.")
        
        guard let transform = self.garSession?.currentFramePair?.garFrame.earth?.cameraGeospatialTransform else {
            print("Failed to build anchors due to invalid geospatial transform in the current GARFrame.")
            return
        }
        
        locations.forEach({ location in
            do {
                try self.garSession?.createAnchorOnRooftop(
                    coordinate: location.location,
                    altitudeAboveRooftop: 0.0,
                    eastUpSouthQAnchor: transform.eastUpSouthQTarget,
                    completionHandler: { self.resolveAnchor($0, forLocation: location, withState: $1) })
            } catch let error {
                print("Error Adding Rooftop Anchor: \(error)")
            }
        })
        
        self.didCreateAnchors = true
    }
    
    /**
     Resolves an anchor for a given location with the specified state.
     
     - Parameters:
        - anchor: The GARAnchor to resolve.
        - location: The Concept3DLocation associated with the anchor.
        - state: The GARRooftopAnchorState indicating the state of the anchor resolution.
     - Warning: If the anchor does not have a valid transform or the state is not `.success`,
                the method will fail to resolve the anchor.
     */
    func resolveAnchor(_ anchor: GARAnchor?, forLocation location: Concept3DLocation, withState state: GARRooftopAnchorState) {
        guard let garAnchor = anchor, garAnchor.hasValidTransform, state == .success else {
            print("Failed to resolve anchor for \(location.name)")
            print("State → \(state.description), Valid Transform → \(String(describing: anchor?.hasValidTransform))")
            return
        }
        let arAnchor = ARAnchor(transform: garAnchor.transform)
        let identifier = AnchorManager.UUIDPair(arIdentifier: arAnchor.identifier, garIdentifier: garAnchor.identifier)
        self.anchorManager.addAnchors(
            uuidPair: identifier,
            data: AnchorManager.AnchorData(arAnchor: arAnchor, garAnchor: garAnchor, location: location, category: self.category))
        self.session.add(anchor: arAnchor)
    }

}
