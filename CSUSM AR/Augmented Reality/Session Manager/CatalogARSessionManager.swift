//
//  CatalogARView+ARSessionDelegate.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/2/23.
//

import Foundation
import ARKit
import ARCore
import Combine

class CatalogARSessionManager: NSObject {

    static let shared = CatalogARSessionManager()

    // MARK: - PROPERTIES
    
    var catalog: [Concept3DLocation] { didSet { self.anchorManager.removeAllAnchors() } }
    let locationManager: LocationManager

    /// Publishers and Subscriptions
    var cancellables: Set<AnyCancellable>
    let vpsPublisher: CurrentValueSubject<Bool, Never>
    let statisticsPublisher: PassthroughSubject<CatalogARSessionStatistics, Never>
    
    /// Related To ARKit
    let session: ARSession
    let scene: SCNScene
    var sceneView: ARSCNView { self.sceneViewRepresentable.unwrappedView }
    var coachingView: ARCoachingOverlayView { self.coachingViewRepresentable.unwrappedView }
    
    /// Related to ARCore
    var garSession: GARSession?
    var didCreateAnchors: Bool
    var localizationState: LocalizationState
    
    /// Thresholds for 'good enough' accuracy. These can be tuned for the application.
    /// We use both 'low' and 'high' values here to avoid flickering state changes.
    let kHorizontalAccuracyLowThreshold: CLLocationAccuracy = 10 /// 10 meters
    let kHorizontalAccuracyHighThreshold: CLLocationAccuracy = 20 /// 20 meters
    let kOrientationYawAccuracyLowThreshold: CLLocationDirectionAccuracy = 15 /// degrees
    let kOrientationYawAccuracyHighThreshold: CLLocationDirectionAccuracy = 25 /// degrees
    /// Time after which the app gives up if good enough accuracy is not achieved.
    let kLocalizationFailureTime: TimeInterval = 3 * 60.0 /// seconds, aka 3 minutes
    /// Time after showing resolving terrain anchors no result yet message.
    let kDurationNoTerrainAnchorResult: TimeInterval = 10 /// seconds
    var lastBeganLocalizing: Date
    
    /// Related to the synchronization of the ARKit and ARCore sessions.
    let anchorManager: AnchorManager
    var error: ARSessionError?

    // MARK: - INITALIZERS AND DEINITALIZERS

    private init(_ locations: [Concept3DLocation] = []) {
        self.cancellables = []
        self.catalog = locations
        
        self.locationManager = LocationManager()
        self.session = ARSession()
        self.scene = SCNScene()
        
        self.anchorManager = AnchorManager()
        
        do { self.garSession = try GARSession(apiKey: Secrets.GoogleAPI.SandboxGoogleAPIKey!, bundleIdentifier: nil) }
        catch let error as GARSessionError { self.error = .garSessionError(error); self.localizationState = .failed }
        catch { self.error = .unexpected(error); self.localizationState = .failed }
        
        var configurationError: NSError?
        self.garSession?.setConfiguration(self.garSessionConfiguration, error: &configurationError)
        if let configurationError = configurationError {
            self.error = .garSessionError(GARSessionError(_nsError: configurationError)); self.localizationState = .failed
        } else { self.localizationState = .pretracking }
        
        self.lastBeganLocalizing = Date()
        self.didCreateAnchors = false
        self.localizationState = .pretracking
        self.vpsPublisher = CurrentValueSubject<Bool, Never>(false)
        self.statisticsPublisher = PassthroughSubject<CatalogARSessionStatistics, Never>()

        super.init()
        
        self.session.delegate = self

        self.cancellables.insert(
            self.locationManager.locationPublisher
                .debounce(for: .seconds(5), scheduler: RunLoop.main).sink {
                    self.garSession?.checkVPSAvailability(coordinate: $0.coordinate) {
                        self.vpsPublisher.send($0 == .available ? true : false) }})
    }
    
    deinit {
        print("deinit CatalogARSessionManager")
        self.locationManager.stopMonitoring()
        self.cancellables.forEach({ $0.cancel() })
    }
    
    // MARK: - SESSION CONFIGURATIONS

    let sessionConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.planeDetection = .horizontal
        return configuration
    }()
    
    let garSessionConfiguration: GARSessionConfiguration = {
        let configuration = GARSessionConfiguration()
        configuration.geospatialMode = .enabled
        configuration.streetscapeGeometryMode = .enabled
        return configuration
    }()

    // MARK: - SWIFT UI VIEWS

    lazy var coachingViewRepresentable: WrappedUIView<ARCoachingOverlayView> = {
        WrappedUIView<ARCoachingOverlayView>({
            $0.activatesAutomatically = false
            $0.goal = .geoTracking
            $0.session = self.session
        })
    }()
    
    lazy var sceneViewRepresentable: WrappedUIView<ARSCNView> = {
        WrappedUIView<ARSCNView>({
            $0.session = self.session
            $0.scene = self.scene
            $0.delegate = self
            $0.automaticallyUpdatesLighting = true;
            $0.autoenablesDefaultLighting = true;
            $0.debugOptions = [.showFeaturePoints]
        })
    }()
    
    // MARK: - EXECUTION STATE

    func run() {
        self.session.run(self.sessionConfiguration, options: [.removeExistingAnchors, .resetTracking])
        self.coachingView.setActive(true, animated: true)
        self.locationManager.startMonitoring()
    }
    
    func pause() {
        self.session.pause()
        self.anchorManager.removeAllAnchors()
        self.locationManager.stopMonitoring()
    }
    
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
    
    /// **NOTE:**  You may resolve multiple anchors at a time, but a session **cannot be tracking more than 100 Rooftop or Terrain anchors at time**. Attempting to resolve more than 100 Rooftop or Terrain anchors will result in `GARSessionErrorCodeResourceExhausted`.
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
                    altitudeAboveRooftop: 15.24,
                    eastUpSouthQAnchor: transform.eastUpSouthQTarget,
                    completionHandler: { self.resolveAnchor($0, forLocation: location, withState: $1) })
            } catch let error {
                print("Error Adding Rooftop Anchor: \(error)")
            }
        })
        
        self.didCreateAnchors = true
    }
    
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
            data: AnchorManager.AnchorData(arAnchor: arAnchor, garAnchor: garAnchor, location: location))
        self.session.add(anchor: arAnchor)
    }

}
