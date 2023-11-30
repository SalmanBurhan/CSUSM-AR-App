//
//  ARViewController.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/27/23.
//

import SwiftUI
import UIKit
import CoreLocation

import ARCore
import ModelIO
import SceneKit.ModelIO
import SceneKit

import simd

struct ARTestView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ARViewController

    func makeUIViewController(context: Context) -> ARViewController {
        return ARViewController()
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        
    }
}

enum LocalizationState {
    case pretracking
    case localizing
    case localized
    case failed
}

enum AnchorType: Int {
    case geospatial
    case terrain
    case rooftop
}

class ARViewController: UIViewController {

    // MARK: - CONSTANTS
    
    // Time after which the app gives up if good enough accuracy is not achieved.
    let kLocalizationFailureTime: TimeInterval = 3 * 60.0
    
    // Time after showing resolving terrain anchors no result yet message.
    let kDurationNoTerrainAnchorResult: TimeInterval = 10

    // This sample allows up to |kMaxAnchors| simultaneous anchors, although in principal
    // ARCore supports an unlimited number.
    let kMaxAnchors: Int = 20
    
    // Thresholds for 'good enough' accuracy. These can be tuned for the application.
    // We use both 'low' and 'high' values here to avoid flickering state changes.
    let kHorizontalAccuracyLowThreshold: CLLocationAccuracy = 10
    let kHorizontalAccuracyHighThreshold: CLLocationAccuracy = 20
    
    let kOrientationYawAccuracyLowThreshold: CLLocationDirectionAccuracy = 15
    let kOrientationYawAccuracyHighThreshold: CLLocationDirectionAccuracy = 25
    
    // Anchor coordinates are persisted between sessions.
    let kSavedAnchorsUserDefaultsKey: String = "anchors"
    
    // MARK: Privacy Notice
    
    // Show privacy notice before using features.
    let kPrivacyNoticeUserDefaultsKey: String = "privacy_notice_acknowledged"
    
    // Title of the privacy notice prompt.
    let kPrivacyNoticeTitle: String = "AR in the real world";
    
    // Content of the privacy notice prompt.
    let kPrivacyNoticeText: String = "To power this session, Google will process visual data from your camera."

    // Link to learn more about the privacy content.
    let kPrivacyNoticeLearnMoreURL: URL = URL(string: "https://developers.google.com/ar/data-privacy")!
    
    // MARK: VPS Notice
    
    // Show VPS availability notice before using features.
    let kVPSAvailabilityNoticeUserDefaultsKey: String = "VPS_availability_notice_acknowledged"
    
    // Title of the VPS availability notice prompt.
    let kVPSAvailabilityTitle: String = "VPS not available"

    // Content of the VPS availability notice prompt.
    let kVPSAvailabilityText: String = "The Google Visual Positioning Service (VPS) is not available at your current location. Location data may not be as accurate."

    // MARK: - PROPERTIES
    
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
    
    /** The current type of anchor to create. */
    var anchorMode: AnchorType = .geospatial

    /** The most recent GARFrame. */
    var garFrame: GARFrame?

    /** Dictionary mapping anchor IDs to SceneKit nodes. */
    var locationNodes: [UUID: SCNNode] = [:] {
        didSet { print("Location Nodes Count: \(self.locationNodes.count)") }
    }
    let locationNodeAccessQueue = DispatchQueue(label: "com.salmanburhan.csusm.locationNodeAccessQueue", attributes: .concurrent)
    
    /** All ARAnchors in current ARSession */
    var allAnchors = [ARAnchor]()
    let anchorsAccessQueue = DispatchQueue(label: "com.salmanburhan.csusm.anchorsAccessQueue", attributes: .concurrent)

    /** The last time we started attempting to localize. Used to implement failure timeout. */
    var lastStartLocalizationDate = Date()

    /** Error message, if any, of last attempted anchor resolution */
    var resolveAnchorErrorMessage: String?

    /** The current localization state. */
    var localizationState: LocalizationState = .pretracking {
        didSet {
            if self.localizationState == .pretracking || self.localizationState == .localizing {
                self.coachingOverlay.setActive(true, animated: true)
            } else {
                self.coachingOverlay.setActive(false, animated: true)
            }
        }
    }

    /** Whether we have restored anchors saved from the previous session. */
    var restoredSavedAnchors = false

    /** Whether the last anchor is terrain anchor. */
    var isLastClickedTerrainAnchorButton: Bool = false

    /** Parent SceneKit node of all StreetscapeGeometries */
    var streetscapeGeometryParentNode: SCNNode = SCNNode()
    
    /** Dictionary mapping StreetscapeGeometry IDs to SceneKit nodes. */
    var streetscapeGeometryNodes: [UUID: SCNNode] = [:]

    /** Is StreetscapeGeometry enabled */
    var isStreetscapeGeometryEnabled: Bool = true

    /** ARKit plane nodes */
    var planeNodes: Set<SCNNode> = []

    /** Active futures for resolving terrain or rooftop anchors. */
    var activeFutures: Int = 0
    
    // MARK: Debug View UI Elements
    var trackingLabel: UILabel = .init()
    var tapScreenLabel: UILabel = .init()
    var statusLabel: UILabel = .init()
    var streetscapeGeometrySwitch: UISwitch = .init()
    var streetscapeGeometrySwitchLabel: UILabel = .init()
    var anchorModeSelector: UIButton = .init()
    var clearAllAnchorsButton: UIButton = .init()

    // MARK: - VIEW CONTROLLER INHERITED METHODS
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupSceneView()
        self.setupStreetscapeGeometry()
        //self.setupDebugView()
        self.setupARSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.clearAllAnchors()
        self.clearAllStreetscapeGeometries()
        self.clearAllPlaneNodes()
        self.locationManager.stopUpdatingLocation()
    
        self.scnView.removeFromSuperview()
        self.arSession.pause()
        self.garSession = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    // MARK: - SETUP
    
    private func setupSceneView() {
        self.scnView.translatesAutoresizingMaskIntoConstraints = false;
        self.scnView.automaticallyUpdatesLighting = true;
        self.scnView.autoenablesDefaultLighting = true;
        
        self.scnView.delegate = self
        // self.scnView.debugOptions = [.showFeaturePoints]

//        self.scene.fogStartDistance = 60
//        self.scene.fogEndDistance = 120
//        self.scene.fogDensityExponent = 1.0
//        self.scene.fogColor = UIColor.black
        
        self.view.addSubview(self.scnView)
        
        self.scnView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.scnView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.scnView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.scnView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        //self.coachingOverlay.delegate = self
        self.coachingOverlay.session = self.arSession
        self.view.addSubview(self.coachingOverlay)

        self.coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.coachingOverlay.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.coachingOverlay.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.coachingOverlay.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.coachingOverlay.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }
    
    private func setupARSession() {
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
    
    private func setupStreetscapeGeometry() {
        self.streetscapeGeometryParentNode.isHidden = false
        self.scene.rootNode.addChildNode(self.streetscapeGeometryParentNode)
    }
        
    private func setupGARSession() {
        guard self.garSession == nil else { return }
        
        do {
            
            self.garSession = try GARSession(apiKey: Secrets.GoogleAPI.SandboxGoogleAPIKey!, bundleIdentifier: nil)
            
            self.localizationState = .failed
            
            if (self.garSession?.isGeospatialModeSupported(.enabled) ?? false) == false {
                self.setErrorStatus("Geospatial is not supported on this device.")
                return
            }
            
            var error: NSError?
            let configuration = GARSessionConfiguration()
            configuration.geospatialMode = .enabled
            configuration.streetscapeGeometryMode = self.isStreetscapeGeometryEnabled ? .enabled : .disabled
            self.streetscapeGeometryParentNode.isHidden = self.isStreetscapeGeometryEnabled ? false : true
            self.garSession?.setConfiguration(configuration, error: &error)
            
            if let error = error {
                self.setErrorStatus("Failed to configure GARSession: \(error.code)")
                print("Failed to configure GARSession: \(error.code)")
                return
            }
            
            self.localizationState = .pretracking
            self.lastStartLocalizationDate = Date()
            
        } catch {
            self.setErrorStatus("Failed to create GARSession: \(error.localizedDescription)")
            print("Failed to create GARSession: \(error.localizedDescription)")
            self.localizationState = .failed
        }
    }
    
    // MARK: - DEBUG VIEW SETUP
    
    private func setupDebugView() {
        let font = UIFont.systemFont(ofSize: 14)
        let boldFont = UIFont.boldSystemFont(ofSize: 14)
        
        self.trackingLabel.translatesAutoresizingMaskIntoConstraints = false
        self.trackingLabel.font = font
        self.trackingLabel.textColor = .white
        self.trackingLabel.backgroundColor = .white.withAlphaComponent(0.5)
        self.trackingLabel.numberOfLines = 6
        self.trackingLabel.text = "TRACKING LABEL"
        
        self.tapScreenLabel.translatesAutoresizingMaskIntoConstraints = false
        self.tapScreenLabel.font = boldFont
        self.tapScreenLabel.textColor = .white
        self.tapScreenLabel.textAlignment = .center
        self.tapScreenLabel.text = "TAP ON SCREEN TO CREATE ANCHOR"
        self.tapScreenLabel.isHidden = true
        
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statusLabel.font = font
        self.statusLabel.textColor = .white
        self.statusLabel.backgroundColor = .white.withAlphaComponent(0.5)
        self.statusLabel.numberOfLines = 2
        self.statusLabel.text = "STATUS LABEL"
        
        self.streetscapeGeometrySwitch.translatesAutoresizingMaskIntoConstraints = false
        self.streetscapeGeometrySwitch.addTarget(self, action: #selector(self.toggleStreetscapeGeometry(_:)), for: .valueChanged)
        self.streetscapeGeometrySwitch.setOn(self.isStreetscapeGeometryEnabled, animated: false)
        
        self.anchorModeSelector.translatesAutoresizingMaskIntoConstraints = false
        self.anchorModeSelector.setTitle("ANCHOR SETTINGS", for: .normal)
        self.anchorModeSelector.setImage(.init(systemName: "gearshape"), for: .normal)
        self.anchorModeSelector.titleLabel?.font = boldFont
        self.anchorModeSelector.menu = self.menuForAnchorSettings()
        self.anchorModeSelector.showsMenuAsPrimaryAction = true
        
        self.streetscapeGeometrySwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        self.streetscapeGeometrySwitchLabel.font = boldFont
        self.streetscapeGeometrySwitchLabel.textColor = .white
        self.streetscapeGeometrySwitchLabel.numberOfLines = 1
        self.streetscapeGeometrySwitchLabel.text = "SHOW GEOMETRY"

        self.clearAllAnchorsButton.translatesAutoresizingMaskIntoConstraints = false
        self.clearAllAnchorsButton.setTitle("CLEAR ALL ANCHORS", for: .normal)
        self.clearAllAnchorsButton.titleLabel?.font = boldFont
        self.clearAllAnchorsButton.addTarget(self, action: #selector(self.clearAllAnchors), for: .touchUpInside)
        
        self.view.addSubview(self.trackingLabel)
        self.view.addSubview(self.tapScreenLabel)
        self.view.addSubview(self.statusLabel)
        self.view.addSubview(self.streetscapeGeometrySwitch)
        self.view.addSubview(self.streetscapeGeometrySwitchLabel)
        self.view.addSubview(self.anchorModeSelector)
        self.view.addSubview(self.clearAllAnchorsButton)
        
        self.trackingLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        self.trackingLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.trackingLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.trackingLabel.heightAnchor.constraint(equalToConstant: 140).isActive = true
        
        self.tapScreenLabel.bottomAnchor.constraint(equalTo: self.statusLabel.topAnchor).isActive = true
        self.tapScreenLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.tapScreenLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.tapScreenLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        self.statusLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        self.statusLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.statusLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.statusLabel.heightAnchor.constraint(equalToConstant: 160).isActive = true
        
        self.streetscapeGeometrySwitch.bottomAnchor.constraint(equalTo: self.statusLabel.bottomAnchor).isActive = true
        self.streetscapeGeometrySwitch.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        self.anchorModeSelector.topAnchor.constraint(equalTo: self.statusLabel.bottomAnchor).isActive = true
        self.anchorModeSelector.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        
        self.streetscapeGeometrySwitchLabel.bottomAnchor.constraint(equalTo: self.statusLabel.bottomAnchor).isActive = true
        self.streetscapeGeometrySwitchLabel.rightAnchor.constraint(equalTo: self.streetscapeGeometrySwitch.leftAnchor).isActive = true
        self.streetscapeGeometrySwitchLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        self.clearAllAnchorsButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        self.clearAllAnchorsButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
    }
    
    private func menuForAnchorSettings() -> UIMenu {
        let actionHandler: (UIAction) -> () = { action in
            switch action.title {
            case "Rooftop":
                self.anchorMode = .rooftop
            case "Terrain":
                self.anchorMode = .terrain
            case "Geospatial":
                self.anchorMode = .geospatial
            default:
                return
            }
            print("Anchor Setting Changed To \(self.anchorMode)")
            self.anchorModeSelector.menu = self.menuForAnchorSettings()
        }
        let children: [UIMenuElement] = [
            UIAction(
                title: "\(self.anchorMode == .geospatial ? "✓ " : "")Geospatial",
                handler: actionHandler
            ),
            UIAction(
                title: "\(self.anchorMode == .terrain ? "✓ " : "")Terrain",
                handler: actionHandler
            ),
            UIAction(
                title: "\(self.anchorMode == .rooftop ? "✓ " : "")Rooftop",
                handler: actionHandler
            )
        ]
        return .init(title: "Anchor Type", children: children)
    }

    private func updateTrackingLabel() {
        if self.localizationState == .failed {
            self.trackingLabel.text = (self.garFrame?.earth?.earthState != .enabled) ? "Bad Earth State: \(self.stringFromGAREarthState(self.garFrame?.earth?.earthState))" : ""
            return
        }
        if self.garFrame?.earth?.trackingState == .paused {
            self.trackingLabel.text = "Not Tracking."
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
        self.trackingLabel.text = String(
            format: """
            Lat/Long: %.6fº, %.6fº
            Accuracy: %.2fm
            Altitude: %.2fm
            Accuracy: %.2fm
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
    
    private func updateStatusLabelAndButtons() {
        switch self.localizationState {
        case .pretracking:
            self.statusLabel.text = "Localizing your device to set anchor."
        case .localizing:
            self.statusLabel.text = "Point your camera at buildings, stores, and signs near you."
            self.tapScreenLabel.isHidden = true
            self.clearAllAnchorsButton.isHidden = true
        case .failed:
            self.statusLabel.text = "Localization not possible.\nClose and open the app to restart."
            self.tapScreenLabel.isHidden = true;
            self.clearAllAnchorsButton.isHidden = true;
            self.anchorModeSelector.isHidden = true;
        case .localized:
            if (self.resolveAnchorErrorMessage != nil) {
              self.statusLabel.text = self.resolveAnchorErrorMessage;
            }
            else if let garFrame = self.garFrame {
                if garFrame.anchors.count == 0 {
                  self.statusLabel.text = "Localization Complete.";
                }
                else if !self.isLastClickedTerrainAnchorButton {
                    self.statusLabel.text = String(
                        format: "Anchor Count: %d/%lu",
                        garFrame.anchors.count + self.activeFutures,
                        self.kMaxAnchors)
                }
                self.clearAllAnchorsButton.isHidden = (garFrame.anchors.count == 0)
                self.tapScreenLabel.isHidden = (garFrame.anchors.count + self.activeFutures >= kMaxAnchors)
                self.anchorModeSelector.isHidden = false
            }
            else {
                self.statusLabel.text = "Localization Complete, But No GAR Frame?"
            }
        }
        
        if self.isStreetscapeGeometryEnabled != self.streetscapeGeometrySwitch.isOn {
            self.isStreetscapeGeometryEnabled = self.streetscapeGeometrySwitch.isOn
            var error: NSError?
            let configuration = GARSessionConfiguration()
            configuration.geospatialMode = .enabled
            configuration.streetscapeGeometryMode = self.isStreetscapeGeometryEnabled ? .enabled : .disabled
            self.garSession?.setConfiguration(configuration, error: &error)
            self.streetscapeGeometryParentNode.isHidden = self.isStreetscapeGeometryEnabled ? false : true
            for planeNode in planeNodes {
                planeNode.isHidden = self.isStreetscapeGeometryEnabled
            }
        }
    }

    private func setErrorStatus(_ message: String) {
        self.statusLabel.text = message
        self.tapScreenLabel.isHidden = true
        self.clearAllAnchorsButton.isHidden = true
    }
    
    // MARK: - DEVICE LOCATION MANAGEMENT
    
    private func checkLocationPermission() {
        switch self.locationManager.authorizationStatus {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            self.setErrorStatus("Location permission denied or restricted.")
            self.locationManager.requestWhenInUseAuthorization()
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            if self.locationManager.accuracyAuthorization != .fullAccuracy {
                self.setErrorStatus("Location permission not granted with full accuracy.")
                return
            }
            self.locationManager.startUpdatingLocation()
            self.setupGARSession()
        default:
            return
        }
    }

    private func checkVPSAvailabilityCoordinates(_ coordinates: CLLocationCoordinate2D) {
        print("Checking VPS availability for coordinates: \(coordinates)")
        self.garSession?.checkVPSAvailability(coordinate: coordinates, completionHandler: { availability in
            if availability != .available {
                //self.showVPSUnavailableNotice()
                print("VPS Unavailable for Coordinates: \(coordinates)")
            }
        })
    }
    
    // MARK: - AR SESSION MANAGEMENT
    
    private func updateLocalizationState() {
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
                    self.addTestAnchors()
                    
                    if (!self.restoredSavedAnchors) {
                        self.restoreSavedAnchors()
                        self.restoredSavedAnchors = true
                        print("restore saved anchors")
                    }
                }
                else if now.timeIntervalSince(self.lastStartLocalizationDate) >= self.kLocalizationFailureTime {
                    self.localizationState = .failed
                }
            }
            else {
                if geospatialTransform == nil {
                    self.localizationState = .localizing
                    self.lastStartLocalizationDate = now
                }
                else if let geospatialTransform = geospatialTransform,
                        geospatialTransform.horizontalAccuracy > self.kHorizontalAccuracyHighThreshold
                        || geospatialTransform.orientationYawAccuracy > self.kOrientationYawAccuracyHighThreshold {
                    self.localizationState = .localizing
                    self.lastStartLocalizationDate = now
                }
            }
        }
    }
    
    private func renderStreetscapeGeometries() {
        guard let streetscapeGeometries = self.garFrame?.streetscapeGeometries,
              self.isStreetscapeGeometryEnabled == true
        else { return }
        
        self.streetscapeGeometryParentNode.isHidden = self.localizationState != .localized
        // Add new streetscapeGeometries which are appearing for the first time.
        for streetscapeGeometry in streetscapeGeometries {
            let identifier = streetscapeGeometry.identifier
            let node = self.streetscapeGeometryNodes[identifier] ?? self.createNode(from: streetscapeGeometry)
            if (self.streetscapeGeometryNodes[identifier] == nil) {
                self.streetscapeGeometryNodes[identifier] = node
                self.streetscapeGeometryParentNode.addChildNode(node)
            }
            node.simdTransform = streetscapeGeometry.meshTransform
            
            // Hide geometries if not actively tracking.
            if streetscapeGeometry.trackingState == .tracking {
                node.isHidden = false
            } else if streetscapeGeometry.trackingState == .paused {
                node.isHidden = true
            } else {
                // Remove permanently stopped geometries.
                node.removeFromParentNode()
                self.streetscapeGeometryNodes.removeValue(forKey: identifier)
            }
        }
    }
    
    private func update(with garFrame: GARFrame) {
        self.garFrame = garFrame
        self.updateLocalizationState()
        //self.updateMarkerNodes()
        self.updateTrackingLabel()
        self.updateStatusLabelAndButtons()
        self.renderStreetscapeGeometries()
    }
    
    private func clearAllPlaneNodes() {
        self.planeNodes.removeAll()
    }
    
    private func clearAllStreetscapeGeometries() {
        for streetscapeGeometry in self.streetscapeGeometryNodes.values {
            streetscapeGeometry.removeFromParentNode()
        }
        self.streetscapeGeometryNodes.removeAll()
    }
    
    @objc private func clearAllAnchors() {
        print("Clear All Anchors")
        guard let garFrame = self.garFrame else {
            print("Unable to unwrap GARFrame.")
            return
        }
        for anchor in garFrame.anchors {
            self.garSession?.remove(anchor)
        }
        for node in self.locationNodes.values {
            node.removeFromParentNode()
        }
        self.locationNodes.removeAll()
        UserDefaults.standard.removeObject(forKey: self.kSavedAnchorsUserDefaultsKey)
        self.isLastClickedTerrainAnchorButton = false
    }
    
    @objc private func toggleStreetscapeGeometry(_ sender: UISwitch) {
        self.isStreetscapeGeometryEnabled = sender.isOn
        if !self.isStreetscapeGeometryEnabled {
            self.clearAllStreetscapeGeometries()
        }
        print("Streetscape Geometry Rendering \(self.isStreetscapeGeometryEnabled ? "Enabled" : "Disabled")")
    }

    // MARK: - NODE CREATION
    
    private func createNode(from streetscapeGeometry: GARStreetscapeGeometry) -> SCNNode {
        let mesh = streetscapeGeometry.mesh
        let data = Data(bytes: mesh.vertices, count: Int(mesh.vertexCount) * MemoryLayout<GARVertex>.size)
        let vertices = SCNGeometrySource(
            data: data,
            semantic: .vertex,
            vectorCount: Int(mesh.vertexCount),
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: 4,
            dataOffset: 0,
            dataStride: 12)
        let triangleData = Data(bytes: mesh.triangles, count: Int(mesh.triangleCount) * MemoryLayout<GARIndexTriangle>.size)
        let indices = SCNGeometryElement(
            data: triangleData,
            primitiveType: .triangles,
            primitiveCount: Int(mesh.triangleCount),
            bytesPerIndex: 4)
        let geometry = SCNGeometry(sources: [vertices], elements: [indices])
        let material = geometry.materials.first
        if streetscapeGeometry.type == .terrain {
            material?.diffuse.contents = UIColor(red: 0.0, green: 0.5, blue: 0, alpha: 0.7)
            material?.isDoubleSided = false
        } else {
            let buildingColors = [
                UIColor(red: 0.7, green: 0.0, blue: 0.7, alpha: 0.8),
                UIColor(red: 0.7, green: 0.7, blue: 0.0, alpha: 0.8),
                UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.8)
            ]
            let randomColor = buildingColors[Int(arc4random()) % buildingColors.count]
            material?.diffuse.contents = randomColor
            material?.blendMode = .replace
            material?.isDoubleSided = false
        }
        let lineGeometry = SCNGeometry(sources: [vertices], elements: [indices])
        let lineMaterial = lineGeometry.materials.first
        lineMaterial?.fillMode = .lines
        lineMaterial?.diffuse.contents = UIColor.black
        let node = SCNNode(geometry: geometry)
        node.addChildNode(SCNNode(geometry: lineGeometry))
        return node
    }
    
    func createMarkerNode(for anchorType: AnchorType) -> SCNNode? {
        
        /*
        guard let objURL = Bundle.main.url(forResource: "geospatial_marker", withExtension: "obj") else {
            print("Unable to find geospatial_marker.obj in the main bundle.")
            return nil
        }

        let markerAsset = MDLAsset(url: objURL)
        
        guard let markerObject = markerAsset.object(at: 0) as? MDLMesh else {
            print("Failed to load MDLMesh from the asset.")
            return nil
        }

        let material = MDLMaterial(name: "baseMaterial", scatteringFunction: MDLScatteringFunction())

        let textureURL = anchorType == .geospatial ?
            Bundle.main.url(forResource: "spatial-marker-baked", withExtension: "png") :
            Bundle.main.url(forResource: "spatial-marker-yellow", withExtension: "png")

        guard let validTextureURL = textureURL else {
            print("Unable to find texture image in the main bundle.")
            return nil
        }

        let materialProperty = MDLMaterialProperty(name: "texture",
                                                   semantic: .baseColor,
                                                   url: validTextureURL)
        material.setProperty(materialProperty)

        guard let submeshes = markerObject.submeshes else {
            print("Unable to unwrap submeshes.")
            return nil
        }
        
        for submesh in submeshes {
            if let submesh = submesh as? MDLSubmesh {
                submesh.material = material
            }
        }

        return SCNNode(mdlObject: markerObject)
        */
        
        
        let radius: CGFloat = 0.5
        let circle = SCNSphere(radius: radius)
        circle.firstMaterial?.diffuse.contents = UIColor.red
        
        let node = SCNNode(geometry: circle)

        return node
    }

    // MARK: - LOCATION ANCHORS
    
    private func updateAnchors(using garAnchors: [GARAnchor]) {
        for garAnchor in garAnchors {
            self.anchorsAccessQueue.async(flags: .barrier) {
                self.updateAnchor(using: garAnchor)
            }
        }
    }
    
    private func updateAnchor(using garAnchor: GARAnchor) {
        if let arAnchor = self.allAnchors.first(where: { $0.name == garAnchor.identifier.uuidString }) {
            switch garAnchor.trackingState {
            case .stopped:
                print("Removing No-Longer-Tracked Anchor: \(garAnchor.identifier)")
                self.arSession.remove(anchor: arAnchor)
            case .tracking:
                if simd_distance(arAnchor.transform.columns.3, garAnchor.transform.columns.3) >= 10.0 {
                    print("Updated distance of tracked anchor: \(garAnchor.identifier) is > 10 meters. updating the anchor.")
                    if let cardNode = self.getNode(forIdentifier: garAnchor.identifier) as? CardNode {
                        self.arSession.remove(anchor: arAnchor)
                        let updatedAnchor = ARAnchor(name: garAnchor.identifier.uuidString, transform: garAnchor.transform)
                        self.arSession.add(anchor: updatedAnchor)
                        self.addNode(cardNode, forIdentifier: garAnchor.identifier)
                    } else {
                        print("Cannot locate Card Node for tracked anchor: \(garAnchor.identifier). Cancelled updating the anchor.")
                    }
                }
            case .paused:
                return
            default:
                print("Unknown GAR Tracking State Encountered While Updating GARAnchor: \(garAnchor.identifier), Unknown State: \(garAnchor.trackingState)")
                return
            }
        }
    }
    
    // MARK: - LOCATION NODES
    
    private func addNode(_ node: SCNNode, forIdentifier identifier: UUID) {
        self.locationNodeAccessQueue.async(flags: .barrier) {
            self.locationNodes[identifier] = node
        }
    }

    private func removeNode(forIdentifier identifier: UUID) {
        locationNodeAccessQueue.async(flags: .barrier) {
            if let _ = self.locationNodes.removeValue(forKey: identifier) {
                print("Removed node associated to anchor: \(identifier)")
            } else {
                print("Unable to remove node associated to anchor: \(identifier). Did a node exist for this anchor?")
            }
            //self.markerNodes[identifier] = nil
        }
    }

    private func getNode(forIdentifier identifier: UUID) -> SCNNode? {
        return self.locationNodes[identifier]
    }

    private func updateNodes() {
        guard let garFrame = self.garFrame else { return }
        let anchors = Dictionary(uniqueKeysWithValues: garFrame.anchors.map { ($0.identifier, $0.transform) })
        // Remove nodes that are no longer present in the ARFrame
        self.locationNodeAccessQueue.async(flags: .barrier) {
            let removedIdentifiers = Set(self.locationNodes.keys).subtracting(anchors.keys)
            removedIdentifiers.forEach { removedIdentifier in
                self.locationNodes[removedIdentifier]?.removeFromParentNode()
                self.locationNodes.removeValue(forKey: removedIdentifier)
            }
            anchors.forEach { identifier, transform in
                if let cardNode = self.getNode(forIdentifier: identifier) as? CardNode {
                    
                    if let pointOfView = self.scnView.pointOfView {
                        DispatchQueue.main.async { cardNode.updateTransform(transform, withScalingFromPOV: pointOfView) }
                    } else {
                        DispatchQueue.main.async { cardNode.updateTransform(transform) }
                    }
                    
                } else {
                    print("unable to map anchor identifier \(identifier) to CardNode.")
                }
            }
        }
    }
    
//    private func addMarkerNode(_ anchor: GARAnchor, type: AnchorType) {
//        //guard let node = self.markerNodes[anchor.identifier] else {
//        //    print("could not add marker node due to failure to unwrap node")
//        //    return
//        //}
//        guard let node = self.createMarkerNode(for: type) else {
//            print("Unable to create Marker Node for Anchor Type \(type)")
//            return
//        }
//        self.locationNodes[anchor.identifier] = node
//        //self.scene.rootNode.addChildNode(node)
//        //self.updateMarkerNode(anchor)
//    }
    
//    private func updateMarkerNode(_ anchor: GARAnchor) {
//        guard let node = self.locationNodes[anchor.identifier],
//              let currentFrame = self.arSession.currentFrame
//        else {
//            //print("could not update marker node due to failure to unwrap marker node and current ARSession frame.")
//            return
//        }

// Rotate the virtual object 180 degrees around the Y axis to make the object face the GL
// camera -Z axis, since camera Z axis faces toward users.

//        let rotationYQuat = simd_quaternion(.pi, simd_float3(0, 1, 0))
//        node.simdTransform = matrix_multiply(anchor.transform, simd_matrix4x4(rotationYQuat))
//        if anchor.hasValidTransform == false {
//            print("Hiding marker node until it's transform is valid again: \(anchor.identifier)")
//            node.isHidden = true
//        } else {
//            node.isHidden = false
//        }
//
//        node.isHidden = self.localizationState != .localized
//        
//
//        // Scale up anchors which are far from the camera.
//        let cameraPosition = SCNNode()
//        cameraPosition.simdTransform = currentFrame.camera.transform
//        let distance = simd_distance(cameraPosition.simdPosition, node.simdPosition)
//        let scale = 1.0 + (simd_clamp(distance, 5.0, 20.0) - 5.0) / 15.0
//        node.simdScale = simd_make_float3(scale, scale, scale)
        
//        print("updating marker node for anchor: \(anchor.identifier)")
//        print("===> isHidden: \(node.isHidden)")
//        print("===> transform: \(node.simdTransform)")
//        print("===> scale: \(node.simdScale)")

//}
    
//    private func updateMarkerNodes() {
//        var currentAnchorIDs = Set<UUID>()
//        
//        objc_sync_enter(self)
//        defer { objc_sync_exit(self) }
//
//        guard let garFrame = self.garFrame else {
//            return
//        }
//        
//        for anchor in garFrame.anchors {
//            self.updateMarkerNode(anchor)
//            
//            currentAnchorIDs.insert(anchor.identifier)
//        }
//
//        // Remove nodes for anchors that are no longer tracking.
//        for anchorID in self.locationNodes.keys {
//            if !currentAnchorIDs.contains(anchorID) {
//                if let node = self.locationNodes[anchorID] {
//                    node.removeFromParentNode()
//                    self.locationNodes.removeValue(forKey: anchorID)
//                }
//            }
//        }
//    }
    
    // MARK: - STRING REPRESENTATIONS
    
    private func stringFromGAREarthState(_ earthState: GAREarthState?) -> String {
        guard let earthState = earthState else { return "INVALID EARTH STATE" }
        return switch earthState {
        case .errorInternal: "ERROR INTERNAL"
        case .errorNotAuthorized: "NOT AUTHORIZED"
        case .errorResourceExhausted: "RESOURCE EXHAUSTED"
        case .enabled: "ENABLED"
        default: "UNKNOWN STATE"
        }
    }

    private func stringFromTerrainState(_ terrainState: GARTerrainAnchorState) -> String {
        switch terrainState {
        case .none: "None";
        case .success: "Success";
        case .errorInternal: "Error Internal";
        /// Depricated Case
        case .taskInProgress: "Task In Progress";
        case .errorNotAuthorized: "Not Authorized";
        case .errorUnsupportedLocation:  "Unsupported Location";
        default: "Unknown";
        }
    }
    
    private func stringFromRooftopState(_ rooftopState: GARRooftopAnchorState) -> String {
        switch rooftopState {
        case .none: "None"
        case .success: "Success"
        case .errorInternal: "Error Internal"
        case .errorNotAuthorized: "Not Authorized"
        case .errorUnsupportedLocation: "Unsupported Location"
        default: "Unknown"
        }
    }
    
    // MARK: - ANCHOR PERSISTENCE AND RESTORATION
    
    private func saveAnchor(
        coordinates: CLLocationCoordinate2D,
        eastUpSouthQTarget: simd_quatf,
        anchorType: AnchorType,
        altitude: CLLocationDistance
    ) {
        let defaults = UserDefaults.standard
        var savedAnchors = defaults.array(forKey: kSavedAnchorsUserDefaultsKey) as? [[String: NSNumber]] ?? []

        var anchorProperties: [String: NSNumber] = [
            "latitude": NSNumber(value: coordinates.latitude),
            "longitude": NSNumber(value: coordinates.longitude),
            "type": NSNumber(value: anchorType.rawValue),
            "x": NSNumber(value: eastUpSouthQTarget.vector[0]),
            "y": NSNumber(value: eastUpSouthQTarget.vector[1]),
            "z": NSNumber(value: eastUpSouthQTarget.vector[2]),
            "w": NSNumber(value: eastUpSouthQTarget.vector[3]),
        ]

        if anchorType == .geospatial {
            anchorProperties["altitude"] = NSNumber(value: altitude)
        }

        savedAnchors.append(anchorProperties)
        defaults.set(savedAnchors, forKey: kSavedAnchorsUserDefaultsKey)
    }
    
    private func restoreSavedAnchors() {
        guard let savedAnchors = UserDefaults.standard.array(forKey: self.kSavedAnchorsUserDefaultsKey) as? [[String: NSNumber]] else {
            print("No saved anchors to restore.")
            return
        }

        for savedAnchor in savedAnchors {
            if let latitude = savedAnchor["latitude"]?.doubleValue,
               let longitude = savedAnchor["longitude"]?.doubleValue,
               let type = savedAnchor["type"]?.intValue,
               let x = savedAnchor["x"]?.floatValue,
               let y = savedAnchor["y"]?.floatValue,
               let z = savedAnchor["z"]?.floatValue,
               let w = savedAnchor["w"]?.floatValue
            {
                let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
                let anchorType = AnchorType(rawValue: type)
                let eastUpSouthQTarget = simd_quatf(vector: simd_float4(x, y, z, w))
                
                if anchorType == .terrain {
                    self.addTerrainAnchor(coodinates: coordinates, eastUpSouthQTarget: eastUpSouthQTarget, shouldSave: false)
                } else if anchorType == .rooftop {
                    self.addRooftopAnchor(coordinates: coordinates, eastUpSouthQTarget: eastUpSouthQTarget, shouldSave: false)
                } else if anchorType == .geospatial, let altitudeValue = savedAnchor["altitude"]?.doubleValue {
                    let altitude = CLLocationDistance(altitudeValue)
                    self.addAnchor(coordinates: coordinates, altitude: altitude, eastUpSouthQTarget: eastUpSouthQTarget, shouldSave: false)
                }
                
            }
        }
    }
    
    private func addTestAnchors() {
        
        let testLocations: [(
            name: String,
            coordinates: CLLocationCoordinate2D,
            metersAboveRooftop: CLLocationDistance)] = [
//                (
//                    name: "Panera Bread",
//                    coordinates: .init(latitude: 33.136702, longitude: -117.182717),
//                    metersAboveRooftop: 5.0
//                ),
//                (
//                    name: "Ssn Diego County Credit Union",
//                    coordinates: .init(latitude: 33.136693, longitude: -117.181936),
//                    metersAboveRooftop: 10.0
//                ),
//                (
//                    name: "Costco Business Center",
//                    coordinates: .init(latitude: 33.13727900299329, longitude: -117.18352037794511),
//                    metersAboveRooftop: 15.0
//                ),
                (
                    name: "Administrative Building",
                    coordinates: .init(latitude: 33.128021, longitude: -117.159615),
                    metersAboveRooftop: 15.24
                ),
                (
                    name: "Academic Hall",
                    coordinates: .init(latitude: 33.128296, longitude: -117.158737),
                    metersAboveRooftop: 15.24
                ),
                (
                    name: "University Hall",
                    coordinates: .init(latitude: 33.128712, longitude: -117.158836),
                    metersAboveRooftop: 15.24
                ),
                (
                    name: "Kellogg Library",
                    coordinates: .init(latitude: 33.129368, longitude: -117.159645),
                    metersAboveRooftop: 15.24
                ),
                (
                    name: "Mangrum Track & Field", /// GAR Should Default To A Terrain Anchor Since It Is Not A Building
                    coordinates: .init(latitude: 33.128948, longitude: -117.161842),
                    metersAboveRooftop: 15.24
                ),
                (
                    name: "Circle Thingies Outside Library", /// GAR Should Default To A Terrain Anchor Since It Is Not A Building,
                    coordinates: .init(latitude: 33.13012710653041, longitude: -117.16004385139169),
                    metersAboveRooftop: 15.24
                ),
                (
                    name: "Epstein Family Veterans Center",
                    coordinates: .init(latitude: 33.127609, longitude: -117.158257),
                    metersAboveRooftop: 15.24
                )
//                (
//                    name: "Neighbor's House",
//                    coordinates: .init(latitude: 33.61079628761317, longitude: -117.08358784378615),
//                    metersAboveRooftop: 1.52
//                )
        ]
        
        guard let eastUpSouthQTarget = self.garFrame?.earth?.cameraGeospatialTransform?.eastUpSouthQTarget else {
            print("Failed to add test anchors due to invalid geospatial transform.")
            return
        }
        
        for testLocation in testLocations {
            print("Adding Rooftop Anchor for \(testLocation.name)")
            self.addRooftopAnchor(
                coordinates: testLocation.coordinates,
                eastUpSouthQTarget: eastUpSouthQTarget,
                metersAboveRooftop: testLocation.metersAboveRooftop,
                name: testLocation.name,
                shouldSave: false
            )
        }
        
    }
    
    // MARK: - ANCHOR CREATION
    
    private func addAnchor(
        coordinates: CLLocationCoordinate2D,
        altitude: CLLocationDistance,
        eastUpSouthQTarget: simd_quatf,
        shouldSave: Bool
    ) {
        guard let garSession = self.garSession else {
            print("Unable To Add Anchor Due To Failure To Unwrap GARSession.")
            return
        }
        // The return value of |createAnchorWithCoordinate:altitude:eastUpSouthQAnchor:error:| is just the
        // first snapshot of the anchor (which is immutable). Use the updated snapshots in
        // |GARFrame.anchors| to get updated values on a frame-by-frame basis.
        do {
            
            let anchor = try garSession.createAnchor(
                coordinate: coordinates,
                altitude: altitude,
                eastUpSouthQAnchor: eastUpSouthQTarget
            )
            
            //self.addMarkerNode(anchor, type: .geospatial)
            
            if shouldSave {
                self.saveAnchor(
                    coordinates: coordinates,
                    eastUpSouthQTarget: eastUpSouthQTarget,
                    anchorType: .geospatial,
                    altitude: altitude
                )
            }
            
        } catch {
            print("Error Adding Anchor: \(error)")
        }
    }
    
    /// **NOTE:**  You may resolve multiple anchors at a time, but a session **cannot be tracking more than 100 Rooftop or Terrain anchors at time**. Attempting to resolve more than 100 Rooftop or Terrain anchors will result in `GARSessionErrorCodeResourceExhausted`.
    private func addTerrainAnchor(
        coodinates: CLLocationCoordinate2D,
        eastUpSouthQTarget: simd_quatf,
        shouldSave: Bool
    ) {
        guard let garSession = self.garSession else {
            print("Unable To Add Terrain Anchor Due To Failure To Unwrap GARSession.")
            return
        }
        do {
            try garSession.createAnchorOnTerrain(
                coordinate: coodinates,
                altitudeAboveTerrain: 0,
                eastUpSouthQAnchor: eastUpSouthQTarget) { anchor, state in
                    self.activeFutures -= 1
                    guard state == .success,
                          let anchor = anchor
                    else {
                        self.resolveAnchorErrorMessage = "Error resolving terrain anchor: \(self.stringFromTerrainState(state))"
                        print("Error resolving terrain anchor: \(self.stringFromTerrainState(state))")
                        return
                    }
                    //self.addMarkerNode(anchor, type: .terrain)
                    DispatchQueue.global(qos: .default).async {
                        if shouldSave {
                            self.saveAnchor(
                                coordinates: coodinates,
                                eastUpSouthQTarget: eastUpSouthQTarget,
                                anchorType: .terrain,
                                altitude: -1.0
                            )
                        }
                    }
                }
        } catch let error as GARSessionError {
            if error.code == .resourceExhausted {
                self.statusLabel.text = "Too many terrain and rooftop anchors have already been held. Clear all anchors to create new ones."
            }
        } catch let error {
            print("Error Adding Terrain Anchor: \(error)")
        }
        self.activeFutures += 1
    }
    
    /// **NOTE:**  You may resolve multiple anchors at a time, but a session **cannot be tracking more than 100 Rooftop or Terrain anchors at time**. Attempting to resolve more than 100 Rooftop or Terrain anchors will result in `GARSessionErrorCodeResourceExhausted`.
    private func addRooftopAnchor(
        coordinates: CLLocationCoordinate2D,
        eastUpSouthQTarget: simd_quatf,
        metersAboveRooftop: CLLocationDistance = 0,
        name: String? = nil,
        shouldSave: Bool
    ) {
        guard let garSession = self.garSession else {
            print("Unable To Add Terrain Anchor Due To Failure To Unwrap GARSession.")
            return
        }
        do {
            try garSession.createAnchorOnRooftop(
                coordinate: coordinates,
                altitudeAboveRooftop: metersAboveRooftop,
                eastUpSouthQAnchor: eastUpSouthQTarget) { garAnchor, state in
                    let anchorName = name ?? garAnchor?.identifier.uuidString ?? "Unknown Name/Identifier"
                    self.activeFutures -= 1
                    guard state == .success,
                          let garAnchor = garAnchor
                    else {
                        self.resolveAnchorErrorMessage = "Error resolving rooftop anchor: \(self.stringFromRooftopState(state))"
                        print("Error resolving rooftop anchor: \(self.stringFromRooftopState(state))")
                        return
                    }
                    print("rooftop anchor: \(anchorName) \(garAnchor.hasValidTransform ? "SUCCESSFULLY" : "FAILED") resolved.")
//                    if garAnchor.hasValidTransform {
                        let arAnchor = ARAnchor(name: garAnchor.identifier.uuidString, transform: garAnchor.transform)
                        self.arSession.add(anchor: arAnchor)
                        
                        let cardNode = CardNode(text: anchorName, systemImage: "building.2.crop.circle")
//                        cardNode.updateTransform(garAnchor.transform)
                        self.addNode(cardNode, forIdentifier: garAnchor.identifier)
                        
//                    } else {
//                        print("Unable to create Node for Anchor Type \(AnchorType.rooftop), Identifier: \(anchorName), Reason: Invalid Transform")
//                    }
                    //self.addMarkerNode(anchor, type: .rooftop)
                    DispatchQueue.global(qos: .default).async {
                        if shouldSave {
                            self.saveAnchor(
                                coordinates: coordinates,
                                eastUpSouthQTarget: eastUpSouthQTarget,
                                anchorType: .rooftop,
                                altitude: -1.0
                            )
                        }
                    }
                }
        } catch let error as GARSessionError {
            if error.code == .resourceExhausted {
                self.statusLabel.text = "Too many terrain and rooftop anchors have already been held. Clear all anchors to create new ones."
            }
        } catch let error {
            print("Error Adding Rooftop Anchor: \(error)")
        }
        self.activeFutures += 1
    }
}

// MARK: - AR Scene View Delegate
extension ARViewController: ARSCNViewDelegate {
 
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if anchor.isKind(of: ARPlaneAnchor.self) == true { return nil }
        
        guard let uuidString = anchor.name,
              let identifier = UUID(uuidString: uuidString),
              let node = self.getNode(forIdentifier: identifier) as? CardNode
        else {
            print("unable to return a node for anchor: \(anchor.name ?? "UNKNOWN-IDENTIFIER")")
            return nil
        }
        print("returning node for anchor: \(node.text)")
//        node.simdTransform = anchor.transform
//        node.position = SCNVector3(0, 0, -0.5)
        return node
    }
    
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        if anchor.isKind(of: ARPlaneAnchor.self) == true { return }
//
//        guard let uuidString = anchor.name,
//              let identifier = UUID(uuidString: uuidString)
//        else {
//            print("anchor for added node does not have an associated GAR Identifier.")
//            return
//        }
//
//        self.addNode(node, forIdentifier: identifier)
//    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if anchor.isKind(of: ARPlaneAnchor.self) == true { return }

        guard let uuidString = anchor.name,
              let identifier = UUID(uuidString: uuidString)
        else {
            print("anchor for removed node does not have an associated GAR Identifier.")
            return
        }
        
        self.removeNode(forIdentifier: identifier)

    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        self.updateNodes()
    }
    
    /*
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor.isKind(of: ARPlaneAnchor.self),
              let planeAnchor = anchor as? ARPlaneAnchor,
              let device = self.scnView.device
        else {
            print("Failed to add plane geometry for node.")
            return
        }
        
//        let altitude = planeAnchor.transform.columns.3.y
//        print("Altitude of the ground outside: \(altitude)")
//        self.streetscapeGeometryParentNode.position = SCNVector3(planeAnchor.center.x, altitude, planeAnchor.center.z)

        let planeGeometry = ARSCNPlaneGeometry(device: device)
        planeGeometry?.update(from: planeAnchor.geometry)
        planeGeometry?.materials.first?.diffuse.contents = UIColor(
            red: 0.0, green: 0.0, blue: 1.0, alpha: 0.7
        )
        
        let planeNode = SCNNode(geometry: planeGeometry)
        node.addChildNode(planeNode)
        self.planeNodes.insert(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard anchor.isKind(of: ARPlaneAnchor.self),
              let planeGeometry = (anchor as? ARPlaneAnchor)?.geometry
        else {
            print("Failed to update plane geometry for node.")
            return
        }
        
        (node.childNodes.first?.geometry as? ARSCNPlaneGeometry)?.update(from: planeGeometry)
    }
    */
}

// MARK: - AR Session Delegate
extension ARViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        self.anchorsAccessQueue.async(flags: .barrier) {
            self.allAnchors.append(contentsOf: anchors)
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        self.anchorsAccessQueue.async(flags: .barrier) {
            self.allAnchors.removeAll { anchor in
                anchors.contains(where: { $0.identifier == anchor.identifier })
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let garSession = self.garSession else {
            //print("Failed to update GARFrame in GARSession with updated ARFrame.")
            return
        }
        
        do {
            let garFrame = try garSession.update(frame)
            self.update(with: garFrame)
            self.updateAnchors(using: garFrame.anchors)
        } catch {
            print("Error updating GARFrame in GARSession: \(error)")
        }
        
//        let cameraPosition = SCNNode()
//        cameraPosition.simdTransform = frame.camera.transform
//        
//        // Get the rotation matrix from the AR camera
//        let rotation = SCNMatrix4(frame.camera.transform)
//
//        // Extract the yaw and roll angles from the rotation matrix
//        let yaw = atan2(rotation.m32, rotation.m33)
//        let roll = atan2(rotation.m21, rotation.m11)
//
//        for node in self.markerNodes.values {
//            let distance = simd_distance(cameraPosition.simdPosition, node.simdPosition)
//            let scale = 1.0 + (simd_clamp(distance, 5.0, 20.0) - 5.0) / 15.0
//            node.simdScale = simd_make_float3(scale, scale, scale)
//            // Set the node's eulerAngles to face the user and rotate 90º on the z-axis
//            node.eulerAngles = SCNVector3(-roll, yaw, -.pi / 2.0)
//        }

    }
    
//    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        guard let camera = self.scnView.pointOfView else { return }
        
//        for node in self.markerNodes.values {
//            DispatchQueue.main.async {
//                print(node.worldPosition, node.transform)
//            }

//            // Calculate distance between camera and node
//            let distance = simd_length(node.simdTransform.columns.3 - camera.simdTransform.columns.3)
//
//            // Define a scaling factor based on distance
//            let scale = min(max(1 / distance, 0.5), 1.5)
//            
//            // Update the scale of the node
//            node.scale = SCNVector3(scale, scale, scale)
//            
//            // Update the node's eulerAngles to face the camera
//            node.eulerAngles.y = camera.eulerAngles.y

//        }
//    }
    
}

// MARK: - Core Location Manager Delegate
extension ARViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("location manager did change authorization")
        self.checkLocationPermission()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        //self.checkVPSAvailabilityCoordinates(location.coordinate)

//        if let currentFrame = self.arSession.currentFrame {
//            self.streetscapeGeometryParentNode.position  = SCNVector3(0, -Float(location.altitude), 0)
//
//            let cameraPosition = SCNNode()
//            cameraPosition.simdTransform = currentFrame.camera.transform
//            let distance = simd_distance(cameraPosition.simdPosition, self.streetscapeGeometryParentNode.simdPosition)
//            let scale = 1.0 + (simd_clamp(distance, 5.0, 20.0) - 5.0) / 15.0
//            self.streetscapeGeometryParentNode.simdScale = simd_make_float3(scale, scale, scale)
//        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error updating location: \(error)")
    }
}
