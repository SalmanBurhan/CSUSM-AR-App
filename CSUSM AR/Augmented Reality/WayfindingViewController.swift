//
//  WayfindingViewController.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/12/23.
//

import UIKit
import ARKit

class WayfindingViewController: UIViewController {
    
    let arSession = ARSessionManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let sceneView = arSession.sceneView
        sceneView.frame = self.view.frame
        self.view.addSubview(sceneView)
    }

    override func viewDidAppear(_ animated: Bool) {
        self.arSession.startSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.arSession.pauseSession()
    }
}
