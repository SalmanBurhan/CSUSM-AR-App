//
//  ARSessionManager.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/12/23.
//

import Foundation
import SceneKit
import ARKit
import ARCore
import SwiftUI

class ARSessionManager: NSObject, ObservableObject {
    
    static var shared = ARSessionManager()
    
    let locationManager = LocationManager.shared
    var locationObserver: NSKeyValueObservation?
    
    var garSession: GARSession?
    var garVPSAvailable: Bool = false
    var latestGARAnchors: [GARAnchor]? = nil

    lazy var sceneView: ARSCNView = {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.session.delegate = self
        sceneView.delegate = self
        sceneView.backgroundColor = .systemBackground
        return sceneView
    }()

    lazy var arConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isAutoFocusEnabled = false
        return configuration
    }()
    
    lazy var garConfiguration: GARSessionConfiguration = {
        let configuration = GARSessionConfiguration()
        configuration.cloudAnchorMode = .enabled
        configuration.geospatialMode = .enabled
        configuration.streetscapeGeometryMode = .enabled
        return configuration
    }()
    
    lazy var renderingHelper: ARRenderer = {
        return ARRenderer(sceneView: self.sceneView)
    }()
    
    var currentGARFrame: GARFrame?
    var currentFrame: ARFrame? {
        return sceneView.session.currentFrame
    }
    
    var cameraTransform: simd_float4x4? {
        return self.sceneView.session.currentFrame?.camera.transform
    }

    var cameraGeoSpatialTransform: GARGeospatialTransform? {
        return self.garSession?.currentFramePair?.garFrame.earth?.cameraGeospatialTransform
    }

    
    var geospatialAccuracy: GeospatialAccuracy = .none {
        didSet {
            if (geospatialAccuracy != oldValue) {
                print("ARSessionManager - Geospatial Accuracy - Value Changed From \(oldValue) to \(geospatialAccuracy)")
            }
        }
    }
    
    /// use this to sequence GARSession operations
    internal var arCoreDispatchQueue = DispatchQueue(label: "arCoreQueue")
    /// the condition object to synchronize the queue
    internal var sessionReadyCondition = NSCondition()
    /// keeps track of whether the GARSession is ready
    internal var sessionReady = false {
        didSet {
            if (oldValue == false && sessionReady == true) {
                self.arCoreDispatchQueue.async {
                    self.addRooftopAnchor()
                }
            }
        }
    }
        
    override init() {
        super.init()
    }
    
    func startSession() {
        self.locationManager.startMonitoring()
        self.locationObserver = LocationManager.shared.observe(\LocationManager.lastLocation, options: [.old, .new]) { manager, change in
            if let lastLocation = manager.lastLocation {
                self.checkVPSAvailability(for: lastLocation)
            }
        }
        sceneView.session.run(arConfiguration, options: [.removeExistingAnchors, .resetTracking])
        startGARSession()
    }
    
    private func waitOnSession() {
        sessionReadyCondition.lock()
        while !sessionReady {
            sessionReadyCondition.wait()
        }
        sessionReadyCondition.unlock()
    }

    func pauseSession() {
        sessionReadyCondition.lock()
        sessionReady = false
        sessionReadyCondition.unlock()
        
        self.locationObserver?.invalidate()
        self.locationManager.stopMonitoring()
        self.renderingHelper.removeRenderedContent()
        sceneView.session.pause()
    }
    
    func addRooftopAnchor() {
        print("GAR Session Stable... Adding Rooftop Anchor")
        do {
            let coordinate = CLLocationCoordinate2D(latitude: 33.127924359014024, longitude: -117.15962709815614)
            if let qAnchor = self.cameraGeoSpatialTransform?.eastUpSouthQTarget {
                try self.garSession?.createAnchorOnRooftop(
                    coordinate: coordinate,
                    altitudeAboveRooftop: 2,
                    eastUpSouthQAnchor: qAnchor,
                    completionHandler: { anchor, state in
                        
                        print("GARRooftopAnchorState: \(String(describing: state))")
                        if let anchor = anchor {
                            if anchor.hasValidTransform {
                                print("GARRooftopAnchor has valid transform.")
                                self.renderingHelper.renderCircle(at: anchor.transform, id: anchor.identifier)
                            } else {
                                print("GARRooftopAnchor has invalid transform.")
                            }
                        }
                    })
            }
        } catch {
            print("Error Adding Rooftop Anchor: \(error)")
        }

    }

    private func startGARSession() {
        do {
            garSession = try GARSession(apiKey: Secrets.GoogleAPI.SandboxGoogleAPIKey!, bundleIdentifier: nil)
            var error: NSError?
            garSession?.setConfiguration(self.garConfiguration, error: &error)
            //garSession?.delegate = self
            if error != nil {
                print("Failed To Configure GARSession with error: \(String(describing: error))")
            }
        } catch {
            print("Failed to Create GARSession with error: \(error)")
        }
    }
    
    private func checkVPSAvailability(for location: CLLocation) {
        self.garSession?.checkVPSAvailability(coordinate: location.coordinate, completionHandler: { availability in
            self.garVPSAvailable = availability == .available
            //print("GARSession | VPS Availability for <Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)> : \(self.garVPSAvailable)")
        })
    }

}
