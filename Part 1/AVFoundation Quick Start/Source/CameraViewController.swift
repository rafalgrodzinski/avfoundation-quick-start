//
//  CameraViewController.swift
//  AVFoundation Quick Start
//
//  Created by Rafal Grodzinski on 27/03/2019.
//  Copyright © 2019 UnalignedByte. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup session
        let session = AVCaptureSession()
        session.sessionPreset = .hd1920x1080
        session.startRunning()

        // Setup input
        guard let inputDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: inputDevice) else {
            return
        }
        session.addInput(input)

        // Setup preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }
}

