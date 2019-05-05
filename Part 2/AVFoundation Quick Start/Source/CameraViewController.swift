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
    @IBOutlet var previewImageView: UIImageView!
    @IBOutlet var closePreviewButton: UIButton!
    private var photoOutput: AVCapturePhotoOutput?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Setup session
        let session = AVCaptureSession()
        session.sessionPreset = .hd1920x1080 // Use HD resolution preview instead of the default one (which could be 4K)
        session.startRunning()

        // Setup input
        guard let inputDevice = AVCaptureDevice.default(for: .video) else {
            // This most probably will be cause by running in the simulator
            show(message: "No Camera")
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { [weak self] isAuthorized in
            // Keep in mind that the access popup is shown only once, so if the user declines access for the first time
            // isAuthorized will always be false (unless the user changes settings manually)
            if !isAuthorized {
                self?.show(message: "No Camera Access. Please, enable camera access in Settings",
                           shouldShowGoToSettingsButton: true)
                return
            }
            guard let input = try? AVCaptureDeviceInput(device: inputDevice) else {
                // From my experience this path is caused by lack of access to the camera, therefore in this app
                // it most probably won't be triggered
                self?.show(message: "No Camera Access")
                return
            }
            // Make sure that the session changs are wrapped in begin/commmit configuration pairs
            session.beginConfiguration()
            session.addInput(input)
            session.commitConfiguration()
        }

        // Setup preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        // Make the preview fill the screen
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)

        // Setup output
        session.beginConfiguration()
        let photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true // Required for isHighResolutionPhotoEnabled of AVCapturePhotoSettings, [default false]
        session.addOutput(photoOutput)
        session.commitConfiguration()
        self.photoOutput = photoOutput
    }

    private func show(message: String, shouldShowGoToSettingsButton: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            let alertViewController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alertViewController.addAction(UIAlertAction(title: "OK", style: .default))

            if shouldShowGoToSettingsButton {
                let goToSettingsAction = UIAlertAction(title: "Go to Settings", style: .default) { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url, options: [:])
                }
                alertViewController.addAction(goToSettingsAction)
            }

            self?.present(alertViewController, animated: true)
        }
    }

    @IBAction private func capturePhotoPressed(_ sender: UIButton) {
        guard let photoOutput = photoOutput else {
            return
        }

        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = .auto // default .off
        photoSettings.isAutoStillImageStabilizationEnabled = true // [default true]
        photoSettings.isAutoDualCameraFusionEnabled = true // [default true]
        photoSettings.isHighResolutionPhotoEnabled = true // [default false]
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    @IBAction private func closePreviewPressed(_ sender: UIButton) {
        previewImageView.isHidden = true
        closePreviewButton.isHidden = true
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoData = photo.fileDataRepresentation() else {
            return
        }
        guard let photoImage = UIImage(data: photoData) else {
            return
        }
        previewImageView.image = photoImage
        previewImageView.isHidden = false
        closePreviewButton.isHidden = false
    }
}

