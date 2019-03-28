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
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Setup session
        let session = AVCaptureSession()
        session.sessionPreset = .hd1920x1080
        session.startRunning()

        // Setup input
        guard let inputDevice = AVCaptureDevice.default(for: .video) else {
            show(message: "No Camera")
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { [weak self] isAuthorized in
            if !isAuthorized {
                self?.show(message: "No Camera Access")
                return
            }
            guard let input = try? AVCaptureDeviceInput(device: inputDevice) else {
                self?.show(message: "No Camera Access")
                return
            }
            session.addInput(input)
        }

        // Setup preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }

    private func show(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alertViewController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alertViewController.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alertViewController, animated: true)
        }
    }
}

