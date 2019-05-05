//
//  CameraViewController.swift
//  AVFoundation Quick Start Part 2
//
//  Created by Rafal Grodzinski on 27/03/2019.
//  Copyright © 2019 UnalignedByte. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    @IBOutlet var previewImageView: UIImageView!
    @IBOutlet var mainImageScrollView: UIScrollView!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var showMainImageButton: UIButton!
    private var photoOutput: AVCapturePhotoOutput?
    private var mainImage: UIImage?
    private var previewImage: UIImage?

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
        // Enable preview image gneration
        if let previewFormat = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey: previewFormat] as [String: Any]
        }
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    @IBAction private func closePreviewPressed(_ sender: UIButton) {
        previewImageView.isHidden = true
        mainImageScrollView.isHidden = true
        closeButton.isHidden = true
        showMainImageButton.isHidden = true
        for subview in mainImageScrollView.subviews {
            subview.removeFromSuperview()
        }
    }

    @IBAction private func showMainImagePressed(_ sender: UIButton) {
        mainImageScrollView.isHidden = false
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // First, get the main image
        guard let photoData = photo.fileDataRepresentation() else {
            return
        }
        mainImage = UIImage(data: photoData)

        // Then, deal with the preview

        // Try getting preview photo orientation from metadata
        var previewPhotoOrientation: CGImagePropertyOrientation?
        if let orientationNum = photo.metadata[kCGImagePropertyOrientation as String] as? NSNumber {
            previewPhotoOrientation = CGImagePropertyOrientation(rawValue: orientationNum.uint32Value)
        }

        // Try getting preview photo
        if let previewPixelBuffer = photo.previewPixelBuffer {
            var previewCiImage = CIImage(cvPixelBuffer: previewPixelBuffer)
            // If we managed to get the oreintation, update the image
            if let previewPhotoOrientation = previewPhotoOrientation {
                previewCiImage = previewCiImage.oriented(previewPhotoOrientation)
            }
            if let previewCgImage = CIContext().createCGImage(previewCiImage, from: previewCiImage.extent) {
                previewImage = UIImage(cgImage: previewCgImage)
            }
        }

        guard let image = previewImage ?? mainImage else {
            return
        }

        previewImageView.image = image
        previewImageView.isHidden = false
        closeButton.isHidden = false

        if let mainImage = mainImage, previewImage != nil {
            mainImageScrollView.contentSize = mainImage.size
            let mainImageView = UIImageView(image: mainImage)
            mainImageScrollView.addSubview(mainImageView)
            showMainImageButton.isHidden = false
        }
    }
}

