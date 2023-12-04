//
//  ExploreARViewController.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/30/23.
//

import UIKit

import ARKit
import ARCore

import CoreLocation

class ExploreARViewController: UIViewController {

    // MARK: - PROPERTIES
    
    let locations: [Concept3DLocation]?

    var isDebugMode: Bool = false
        
    // Time after which the app gives up if good enough accuracy is not achieved.
    let kLocalizationFailureTime: TimeInterval = 3 * 60.0 /// seconds, aka 3 minutes
    
    // Time after showing resolving terrain anchors no result yet message.
    let kDurationNoTerrainAnchorResult: TimeInterval = 10 /// seconds

    // Thresholds for 'good enough' accuracy. These can be tuned for the application.
    // We use both 'low' and 'high' values here to avoid flickering state changes.
    let kHorizontalAccuracyLowThreshold: CLLocationAccuracy = 10 /// 10 meters
    let kHorizontalAccuracyHighThreshold: CLLocationAccuracy = 20 /// 20 meters
    
    let kOrientationYawAccuracyLowThreshold: CLLocationDirectionAccuracy = 15 /// degrees
    let kOrientationYawAccuracyHighThreshold: CLLocationDirectionAccuracy = 25 /// degrees

    /** Location manager used to request and check for location permissions. */
    var locationManager: CLLocationManager = .init()
    
    /** ARKit session. */
    var arSession: ARSession { self.scnView.session }
    
    /** ARCore session, used for geospatial localization. Created after obtaining location permission. */
    var garSession: GARSession?

    /** A view that shows an AR enabled camera feed and 3D content. */
    var scnView: ARSCNView = ARSCNView(frame: .zero)
    
    /** A view that displays standardized onboarding instructions to direct users toward a specific goal.*/
    var coachingOverlay: ARCoachingOverlayView = ARCoachingOverlayView(frame: .zero)

    /** SceneKit scene used for rendering markers. */
    var scene: SCNScene { self.scnView.scene }
    
    /** The most recent GARFrame. */
    var garFrame: GARFrame?
    
    /** Parent SceneKit node of all StreetscapeGeometries */
    var streetscapeGeometryParentNode: SCNNode = SCNNode()
    
    /** Dictionary mapping StreetscapeGeometry IDs to SceneKit nodes. */
    var streetscapeGeometryNodes: [UUID: SCNNode] = [:]
    
    /** The last time we started attempting to localize. Used to implement failure timeout. */
    var lastBeganLocalizing: Date = Date()
    
    var anchorManager: AnchorManager = .init()
    
    var trackingStateLogLine: String = "" {
        didSet { print("----\n\(self.trackingStateLogLine)\n----") }
    }

    /** The current localization state. */
    var localizationState: LocalizationState = .pretracking {
        didSet { self.updateCoachingVisibility() }
    }

    init(_ locations: [Concept3DLocation]) {
        print("Initializing ExploreARViewController with \(locations.count) Locations.")
        self.locations = locations
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSceneView()
        self.setupARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.arSession.pause()
        self.locationManager.stopUpdatingLocation()
    }

    // MARK: - SETUP
    
    func setupSceneView() {
        self.scnView.translatesAutoresizingMaskIntoConstraints = false;
        self.scnView.automaticallyUpdatesLighting = true;
        self.scnView.autoenablesDefaultLighting = true;

        self.scnView.delegate = self
        self.scnView.debugOptions = [.showFeaturePoints]

        self.view.addSubview(self.scnView)
        
        self.scnView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.scnView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.scnView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.scnView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        self.coachingOverlay.session = self.arSession
        self.view.addSubview(self.coachingOverlay)

        self.coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.coachingOverlay.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.coachingOverlay.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.coachingOverlay.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.coachingOverlay.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }
    
    func setupARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.planeDetection = .horizontal
        
        self.coachingOverlay.activatesAutomatically = false
        self.coachingOverlay.goal = .tracking

        self.arSession.delegate = self
        self.arSession.run(configuration)
        self.coachingOverlay.setActive(true, animated: true)

        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.delegate = self
        self.checkLocationPermission()
    }
    
    func setupGARSession() {
        guard self.garSession == nil else { return }
        
        do {
            self.garSession = try GARSession(apiKey: Secrets.GoogleAPI.SandboxGoogleAPIKey!, bundleIdentifier: nil)
            
            self.localizationState = .failed
            
            if (self.garSession?.isGeospatialModeSupported(.enabled) ?? false) == false {
                print("Geospatial is not supported on this device.")
                return
            }
            
            var error: NSError?
            let configuration = GARSessionConfiguration()
            configuration.geospatialMode = .enabled
            configuration.streetscapeGeometryMode = self.isDebugMode ? .enabled : .disabled
            
            self.streetscapeGeometryParentNode.isHidden = self.isDebugMode ? false : true
            self.garSession?.setConfiguration(configuration, error: &error)
            
            if let error = error {
                print("Failed to configure GARSession: \(error.code)")
                return
            }
            
            self.localizationState = .pretracking
            self.lastBeganLocalizing = Date()
            
        } catch {
            print("Failed to create GARSession: \(error.localizedDescription)")
            self.localizationState = .failed
        }
    }
        
    // MARK: - DEVICE LOCATION MANAGEMENT
    
    // TODO: Location Permissions Helper View
    func checkLocationPermission() {
        switch self.locationManager.authorizationStatus {
            
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        
        case .denied, .restricted:
            print("Location permission denied or restricted.")
            self.locationManager.requestWhenInUseAuthorization()
        
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
        
            guard self.locationManager.accuracyAuthorization == .fullAccuracy else {
                print("Location permission not granted with full accuracy.")
                return
            }
            
            self.locationManager.startUpdatingLocation()
            self.setupGARSession()
        
        default:
            return
            
        }
    }

    // TODO: Let The User Know
    private func checkVPSAvailability(_ coordinates: CLLocationCoordinate2D) {
        print("Checking VPS availability for coordinates: \(coordinates)")
        self.garSession?.checkVPSAvailability(coordinate: coordinates, completionHandler: { availability in
            if availability != .available {
                print("VPS Unavailable for Coordinates: \(coordinates)")
            }
        })
    }
    
    // MARK: - AR SESSION MANAGEMENT
    
    func updateCoachingVisibility() {
        print("Localization State Changed: \(self.localizationState)")
        self.coachingOverlay.setActive(
            self.localizationState == .pretracking ||
            self.localizationState == .localizing
            ? true : false, animated: true)
    }
    
    func updateLocalizationState() {
        let geospatialTransform = self.garFrame?.earth?.cameraGeospatialTransform
        let now = Date()
        
        if self.garFrame?.earth?.earthState != .enabled {
            self.localizationState = .failed
        }
        
        else if self.garFrame?.earth?.trackingState != .tracking {
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
                    if let locations = locations {
                        self.createAnchors(for: locations)
                    }
                    
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
    
    // MARK: - DEBUGGING
    
    func updateTrackingState() {
        if self.localizationState == .failed {
            self.trackingStateLogLine = (self.garFrame?.earth?.earthState != .enabled) ? "Bad Earth State: \(String(describing: self.garFrame?.earth?.earthState))" : ""
            return
        }
        if self.garFrame?.earth?.trackingState == .paused {
            self.trackingStateLogLine = "Not Tracking."
            return
        }
        
        // This can't be nil if currently tracking and in a good EarthState.
        guard let geospatialTransform = self.garFrame?.earth?.cameraGeospatialTransform
        else {
            print("Geospatial Transform should not have been nil if currently tracking and in a good EarthState.")
            return
        }
        
        let cameraQuaternion = geospatialTransform.eastUpSouthQTarget
        // Note: the altitude value here is relative to the WGS84 ellipsoid (equivalent to
        // |CLLocation.ellipsoidalAltitude|).
        self.trackingStateLogLine = String(
            format: """
            Lat/Long: %.6fº, %.6fº | Accuracy: %.2fm
            Altitude: %.2fm | Accuracy: %.2fm
            Orientation: [%.1f, %.1f, %.1f, %.1f]
            Yaw Accuracy: %.1fº
            """,
            geospatialTransform.coordinate.latitude,
            geospatialTransform.coordinate.longitude,
            geospatialTransform.horizontalAccuracy,
            geospatialTransform.altitude,
            geospatialTransform.verticalAccuracy,
            cameraQuaternion.vector[0],
            cameraQuaternion.vector[1],
            cameraQuaternion.vector[2],
            cameraQuaternion.vector[3],
            geospatialTransform.orientationYawAccuracy)
    }

}
