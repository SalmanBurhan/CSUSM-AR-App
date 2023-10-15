//
//  ViewController.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 9/22/23.
//

import UIKit
import SceneKit
import ARKit
import ARCore
// import CoreLocation // Already Imported From ARKit or ARCore

class RewrittenViewController: UIViewController {
    
    enum LocalizationState: Int {
        case localizationStatePretracking = 0
        case localizationStateLocalizing = 1
        case localizationStateLocalized = 2
        case localizationStateFailed = -1
    }

    @IBOutlet var sceneView: ARSCNView!
    
    var arSession: ARSession?
    var scene: SCNScene?
    var garSession: GARSession?
    var garFrame: GARFrame?
    var locationManager: CLLocationManager?
    
    var planeNodes: NSMutableSet = .init()
    var streetscapeGeometryNodes: Dictionary<UUID, SCNNode> = .init()
    var streetscapeGeometryParentNode = SCNNode()
    var activeFeatures: Int = 0
    
    var isStreetscapeGeometryEnabled: Bool = true
    var localizationState: LocalizationState = .localizationStateFailed
    var lastStartLocalizationDate: Date? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.automaticallyUpdatesLighting = true
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        self.scene = self.sceneView.scene
        self.arSession = self.sceneView.session

        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        self.streetscapeGeometryParentNode.isHidden = false
        self.scene?.rootNode.addChildNode(self.streetscapeGeometryParentNode)

    }
    
    func setupARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.planeDetection = .horizontal
        
        self.arSession?.delegate = self
        self.arSession?.run(configuration)
        
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func checkLocationPermission() {
        let authorizationStatus = self.locationManager?.authorizationStatus
        print("checkLocationPermission ==> \(String(describing: authorizationStatus))")
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            if (self.locationManager?.accuracyAuthorization != .fullAccuracy) {
                print("Location Permission Not Granted With Full Accuracy.")
            }
            print("Requesting Location...")
            self.locationManager?.requestLocation()
            self.setupGARSession()
        } else if authorizationStatus == .notDetermined {
            self.locationManager?.requestWhenInUseAuthorization()
        } else {
            print("Location Permission Denied or Restricted.")
        }
    }
    
    func setupGARSession() {
        guard self.garSession == nil else { print("setupGARSession() ==> GARSession Already Setup"); return }
        print("setupGARSession() ==> Not Setup, Attempting...")
        do {
            
            let garSession = try GARSession(apiKey: GoogleAPI.sandbox.apiKey, bundleIdentifier: nil)
            if !garSession.isGeospatialModeSupported(.enabled) { print("GARGeospatialModeEnabled Is Not Supported On This Device.") }
            
            let configuration = GARSessionConfiguration()
            configuration.geospatialMode = .enabled
            configuration.streetscapeGeometryMode = self.isStreetscapeGeometryEnabled ? .enabled : .disabled

            var error: NSError?
            garSession.setConfiguration(configuration, error: &error)
            if let configurationError = error {
                print("Failed to Configure GAR Session With Error: \(configurationError.localizedDescription)")
                return
            }
            self.localizationState = .localizationStatePretracking
            self.lastStartLocalizationDate = .now
            
        } catch(let error) {
            print("Failed To Create GARSession With Error: \(error.localizedDescription)")
        }
    }
    
    func checkVPSAvailability(with coordinate: CLLocationCoordinate2D) {
        print("checkVPSAvailability(with coordinate: \(coordinate)")
        self.garSession?.checkVPSAvailability(coordinate: coordinate, completionHandler: { availability in
            print("VPS Availability ==> \(availability)")
            if availability != .available {
                self.showVPSUnavailableNotice()
            }
        })
    }
    
    func showVPSUnavailableNotice() {
        print(Constants.AR.kVPS_AVAILABILITY_TEXT)
    }
    
    func update(with garFrame: GARFrame) {
        print("update(with garFrame: \(garFrame)")
        self.garFrame = garFrame
        self.updateLocalizationState()
        //self.updateMarkerNodes()
        self.renderStreetscapeGeometries()
    }
    
    func updateLocalizationState() {
        print("updateLocaliationState()")
        let now = Date.now

        //
        // MARK: TODO - WHAT THE FUCK? Enum doesn't even contain the values used in Google's Example Code... To Investigate... self.kill()?
        //
        if (self.garFrame?.earth?.earthState != .enabled) {
            self.localizationState = .localizationStateFailed
        } else if (self.garFrame?.earth?.trackingState != .tracking) {
            self.localizationState = .localizationStatePretracking
        } else {
            if (self.localizationState == .localizationStatePretracking) {
                self.localizationState = .localizationStateLocalizing
            } else if (self.localizationState == .localizationStateLocalizing) {
                if let geospatialTransform = self.garFrame?.earth?.cameraGeospatialTransform {
                    if (geospatialTransform.horizontalAccuracy <= Constants.AR.kHorizontalAccuracyLowThreshold
                        && geospatialTransform.orientationYawAccuracy <= Constants.AR.kOrientationYawAccuracyLowThreshold) {
                        self.localizationState = .localizationStateLocalized
                    }
                } else if let lastStartLocalizationDate = self.lastStartLocalizationDate {
                    if (now.timeIntervalSince(lastStartLocalizationDate) >= Constants.AR.kLocalizationFailureTime) {
                        self.localizationState = .localizationStateFailed
                    }
                }
            } else {
                if let geospatialTransform = self.garFrame?.earth?.cameraGeospatialTransform {
                    if (geospatialTransform.horizontalAccuracy > Constants.AR.kHorizontalAccuracyHighThreshold ||
                        geospatialTransform.orientationYawAccuracy > Constants.AR.kOrientationYawAccuracyHighThreshold) {
                        self.localizationState = .localizationStateLocalizing
                        self.lastStartLocalizationDate = now
                    }
                }
            }
        }
    }
    
    func renderStreetscapeGeometries() {
        print("renderStreetscapeGeometries()")
        guard let streetscapeGeomteries = self.garFrame?.streetscapeGeometries
        else { return }
        print("streetscapeGeometries ==> \(streetscapeGeomteries.count) Count")
        
        self.streetscapeGeometryParentNode.isHidden = self.localizationState != .localizationStateLocalized
        print("streetscapeGeometryParentNode.isHidden = \(self.streetscapeGeometryParentNode.isHidden)")
        
        for streetscapeGeomtery in streetscapeGeomteries {
            if !self.streetscapeGeometryNodes.contains(where: { $0.key == streetscapeGeomtery.identifier }) {
                let node = self.streetscapeGeometryToSCNNode(streetscapeGeomtery)
                self.streetscapeGeometryNodes[streetscapeGeomtery.identifier] = node
                self.streetscapeGeometryParentNode.addChildNode(node)
            }
            
            let node = self.streetscapeGeometryNodes[streetscapeGeomtery.identifier]
            node?.simdTransform = streetscapeGeomtery.meshTransform
            
            // Hide Geometries if Not Actively Tracking
            if (streetscapeGeomtery.trackingState == .tracking) {
                node?.isHidden = false
            } else if (streetscapeGeomtery.trackingState == .paused) {
                node?.isHidden = true
            } else {
                node?.removeFromParentNode()
                self.streetscapeGeometryNodes.removeValue(forKey: streetscapeGeomtery.identifier)
            }
        }
        
    }
    
    func streetscapeGeometryToSCNNode(_ streetscapeGeometry: GARStreetscapeGeometry) -> SCNNode {
        print("streetscapeGeometryToSCNNode(\(streetscapeGeometry)")
        let mesh = streetscapeGeometry.mesh
        
        let data = Data(
            bytes: mesh.vertices,
            count: Int(mesh.vertexCount) * MemoryLayout.size(ofValue: GARVertex.self)
        )
        
        let vertices = SCNGeometrySource(
            data: data,
            semantic: .vertex,
            vectorCount: Int(mesh.vertexCount),
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: 4,
            dataOffset: 0,
            dataStride: 12
        )
        
        let triangleData = Data(
            bytes: mesh.triangles,
            count: Int(mesh.triangleCount) * MemoryLayout.size(ofValue: GARIndexTriangle.self)
        )
        
        let indices = SCNGeometryElement(
            data: triangleData,
            primitiveType: .triangles,
            primitiveCount: Int(mesh.triangleCount),
            bytesPerIndex: 4
        )
        
        let geometry = SCNGeometry(
            sources: [vertices],
            elements: [indices]
        )
        
        let material = geometry.firstMaterial
        
        if (streetscapeGeometry.type == .terrain) {
            material?.diffuse.contents = UIColor(red: 0, green: 0.5, blue: 0, alpha: 0.7)
            material?.isDoubleSided = false
        } else {
            let buildingColors = [
                UIColor(red: 0.7, green: 0.0, blue: 0.7, alpha: 0.8),
                UIColor(red: 0.7, green: 0.7, blue: 0.0, alpha: 0.8),
                UIColor(red: 0.0, green: 0.7, blue: 0.7, alpha: 0.8)
            ]
            //let randomColor = buildingColors[Int(arc4random()) % buildingColors.count]
            material?.diffuse.contents = buildingColors.randomElement()
            material?.blendMode = .replace
            material?.isDoubleSided = false
        }
        
        let lineGeometry = SCNGeometry(
            sources: [vertices],
            elements: [indices]
        )
        
        let lineMaterial = lineGeometry.firstMaterial
        lineMaterial?.fillMode = .lines
        lineMaterial?.diffuse.contents = UIColor.black
        
        let node = SCNNode(geometry: lineGeometry)
        node.addChildNode(.init(geometry: lineGeometry))
        
        print("SCNNode from Streetscape Geometry ==> \(node)")
        return node
    }
    
}

// MARK: - CLLocationManager Delegate
extension RewrittenViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("locationManagerDidChangeauthorization(_ manager: \(manager)")
        self.checkLocationPermission()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locationManager(_ manager: \(manager), didUpdateLocationsWithCount: \(locations.count)")
        guard let location = locations.last else { return }
        self.checkVPSAvailability(with: location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed To Obtain User Location With Error: \(error.localizedDescription)")
    }
    
}


// MARK: - ARSCNView Delegate
extension RewrittenViewController: ARSCNViewDelegate {

/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //print("renderer(\(renderer), didAdd: \(node), for: \(anchor)")
        guard let device = self.sceneView.device,
              anchor.isKind(of: ARPlaneAnchor.self)
        else { return }
        //print("device ==> \(device)")
        
        let planeAnchor = ARPlaneAnchor(anchor: anchor)
        let planeGeometry = ARSCNPlaneGeometry(device: device)
        planeGeometry?.update(from: planeAnchor.geometry)
        planeGeometry?.firstMaterial?.diffuse.contents = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.7)
        let planeNode = SCNNode(geometry: planeGeometry)
        node.addChildNode(planeNode)
        self.planeNodes.add(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        //print("renderer(\(renderer), didUpdate: \(node), for: \(anchor)")
        if anchor.isKind(of: ARPlaneAnchor.self) {
            let planeAnchor = ARPlaneAnchor(anchor: anchor)
            let planeNode = node.childNodes.first?.geometry as? ARSCNPlaneGeometry
            planeNode?.update(from: planeAnchor.geometry)
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        //print("renderer(\(renderer), didRemove: \(node), for: \(anchor)")
        if anchor.isKind(of: ARPlaneAnchor.self) {
            let planeNode = node.childNodes.first
            planeNode?.removeFromParentNode()
            self.planeNodes.remove(planeNode as Any)
        }
    }

}

// MARK: - ARSession Delegate
extension RewrittenViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //print("session(\(session), didUpdate: \(frame)")
        guard let garSession = self.garSession, self.localizationState != .localizationStateFailed,
              let garFrame = try? garSession.update(frame)
        else { return }
        
        self.update(with: garFrame)
    }
    
}
