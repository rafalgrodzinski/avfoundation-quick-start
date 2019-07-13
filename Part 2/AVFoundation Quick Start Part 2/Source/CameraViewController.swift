//
//  CameraViewController.swift
//  AVFoundation Quick Start Part 2
//
//  Created by Rafal Grodzinski on 27/03/2019.
//  Copyright © 2019 UnalignedByte. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {
    @IBOutlet private var previewImageView: UIImageView!
    @IBOutlet private var mainImageView: UIImageView!
    // The constraints are used for correct placement of the photo in the scroll view
    @IBOutlet private var mainImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var mainImageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private var mainImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var mainImageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var mainPhotoScrollView: UIScrollView!
    @IBOutlet private var showMainPhotoButton: UIButton!
    @IBOutlet private var savePhotoButton: UIButton!
    @IBOutlet private var closeButton: UIButton!
    private var photoOutput: AVCapturePhotoOutput?
    private var photoData: Data?
    private var videoUrl: URL?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Setup session
        let session = AVCaptureSession()
        session.sessionPreset = .photo // Use .photo preset in order for live photo capture to work

        // Setup camera preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        // Make the preview fill the screen
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)

        setupVideoInput(for: session) { [weak self] in
            self?.setupAudioInput(for: session) {
                self?.setupPhotoOutputAndStartSession(session)
            }
        }
    }

    private func setupVideoInput(for session: AVCaptureSession, completedCallback: @escaping () -> Void) {
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            // This most probably will be caused by running in the simulator (or if the camera is broken)
            show(message: "No Video Capture Device")
            completedCallback()
            return
        }

        AVCaptureDevice.requestAccess(for: .video) { [weak self] isAuthorized in
            // Keep in mind that the access popup is shown only once, so if the user declines access for the first time
            // isAuthorized will always be false (unless the user changes settings manually)
            if !isAuthorized {
                self?.show(message: "No Camera Access. Please, enable camera access in Settings",
                           shouldShowGoToSettingsButton: true)
                completedCallback()
                return
            }

            guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                // From what I've seen this path is caused by lack of access to the camera, therefore in this app
                // it most probably won't be triggered
                self?.show(message: "No Video Input Device")
                completedCallback()
                return
            }

            // Make sure that the session changs are wrapped in begin/commmit configuration pairs
            session.beginConfiguration()
            session.addInput(videoInput)
            session.commitConfiguration()

            completedCallback()
        }
    }

    private func setupAudioInput(for session: AVCaptureSession, completedCallback: @escaping () -> Void) {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            show(message: "No Audio Capture Device")
            completedCallback()
            return
        }

        // Since live photos can also contain audio, we request access to the microphone
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] isAuthorized in
            if !isAuthorized {
                self?.show(message: "No Microphone Access. Please, enable microphone access in Settings",
                           shouldShowGoToSettingsButton: true)
                completedCallback()
                return
            }

            guard let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
                self?.show(message: "No Audio Input Device")
                completedCallback()
                return
            }

            session.beginConfiguration()
            session.addInput(audioInput)
            session.commitConfiguration()

            completedCallback()
        }
    }

    private func setupPhotoOutputAndStartSession(_ session: AVCaptureSession) {
        // Setup output
        session.beginConfiguration()
        let photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true // Required for isHighResolutionPhotoEnabled of AVCapturePhotoSettings, default is false
        session.addOutput(photoOutput)
        // Required for live photo capture, default is false
        // Must be done after adding AVCapturePhotoOutput ot the session
        if photoOutput.isLivePhotoCaptureSupported {
            photoOutput.isLivePhotoCaptureEnabled = true
        }
        self.photoOutput = photoOutput
        session.commitConfiguration()
        session.startRunning() // Start session only once isLivePhotoCaptureEnabled is set to true
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
        photoSettings.flashMode = .auto // default is .off
        photoSettings.isAutoStillImageStabilizationEnabled = true // default is true
        photoSettings.isAutoDualCameraFusionEnabled = true // default is true
        photoSettings.isHighResolutionPhotoEnabled = true // default is false

        // Enable preview image gneration
        if let previewFormat = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey: previewFormat] as [String: Any]
        }

        // Enable live photo
        if photoOutput.isLivePhotoCaptureEnabled {
            photoSettings.livePhotoMovieFileURL = URL.tempFile(withFileExtension: "mov")
            // Select first of the available video codecs (optional)
            if let livePhotoFormat = photoOutput.availableLivePhotoVideoCodecTypes.first {
                photoSettings.livePhotoVideoCodecType = livePhotoFormat
            }
        }

        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    @IBAction private func closePreviewPressed(_ sender: UIButton) {
        // Hide all the additional views
        previewImageView.isHidden = true
        mainPhotoScrollView.isHidden = true
        closeButton.isHidden = true
        showMainPhotoButton.isHidden = true
        savePhotoButton.isHidden = true
        // Remove images
        previewImageView.image = nil
        mainImageView.image = nil
    }

    @IBAction private func showMainPhotoPressed(_ sender: UIButton) {
        mainPhotoScrollView.isHidden = false
    }

    @IBAction private func savePhotoPressed(_ sender: UIButton) {
        guard let photoData = photoData else {
            return
        }
        saveToPhotosLibrary(photoData: photoData, videoUrl: videoUrl)
    }

    private func showInScrollView(image: UIImage) {
        // Display the desired image
        mainImageView.image = image
        // Calculate the appropriate zoom scale given the image and scroll size
        let widthScale = mainPhotoScrollView.bounds.width / image.size.width
        let heightScale = mainPhotoScrollView.bounds.height / image.size.height
        let scale = min(widthScale, heightScale)
        mainPhotoScrollView.minimumZoomScale = scale
        mainPhotoScrollView.zoomScale = scale
        // Make sure new image appropriately updated layout
        view.layoutIfNeeded()
        updateMainImageViewConstraints()
    }

    private func updateMainImageViewConstraints() {
        // Calculcate appropriate offsets so the displayed image is centered in the scroll view
        var xOffset = (mainPhotoScrollView.frame.width - mainImageView.frame.width) * 0.5
        xOffset = max(xOffset, 0.0)
        mainImageViewLeadingConstraint.constant = xOffset
        mainImageViewTrailingConstraint.constant = xOffset

        var yOffset = (mainPhotoScrollView.frame.height - mainImageView.frame.height) * 0.5
        yOffset = max(yOffset, 0.0)
        mainImageViewTopConstraint.constant = yOffset
        mainImageViewBottomConstraint.constant = yOffset
    }

    private func saveToPhotosLibrary(photoData: Data, videoUrl: URL?) {
        PHPhotoLibrary.requestAuthorization { [weak self] (status: PHAuthorizationStatus) in
            // Make sure the user has granted access to the photo library
            guard status == .authorized else {
                self?.show(message: "No Photo Library Access. Please, enable photo library access in Settings",
                           shouldShowGoToSettingsButton: true)
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                // Add captured photo
                creationRequest.addResource(with: .photo, data: photoData, options: nil)
                // Add captured live photo's video file
                if let videoUrl = videoUrl {
                    creationRequest.addResource(with: .pairedVideo, fileURL: videoUrl, options: nil)
                }
            }, completionHandler: { [weak self] (isSuccessful: Bool, error: Error?) in
                if let error = error {
                    self?.show(message: error.localizedDescription)
                } else {
                    // Inform the user that the save to photo library has succeeded
                    let message = videoUrl != nil ? "Live Photo Saved" : "Photo Saved"
                    self?.show(message: message)
                }
            })
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Get the main image
        guard let photoData = photo.fileDataRepresentation() else {
            return
        }
        let mainImage = UIImage(data: photoData)

        // Get the preview
        // First try getting preview photo orientation from metadata
        var previewPhotoOrientation: CGImagePropertyOrientation?
        if let orientationNum = photo.metadata[kCGImagePropertyOrientation as String] as? NSNumber {
            previewPhotoOrientation = CGImagePropertyOrientation(rawValue: orientationNum.uint32Value)
        }

        // Then try getting the photo preview
        var previewImage: UIImage?
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

        // Make sure we at least have one image
        guard let image = previewImage ?? mainImage else {
            return
        }

        // Keep photo data and enable the save button (if we're not using live photo capture)
        self.photoData = photoData
        if !(photoOutput?.isLivePhotoCaptureEnabled ?? false) {
            savePhotoButton.isHidden = false
        }

        // If that's the case, show it as the preview
        previewImageView.image = image
        previewImageView.isHidden = false
        closeButton.isHidden = false

        // If we have both the main and the preview image, show main image in a scroll view
        if let mainImage = mainImage, previewImage != nil {
            showInScrollView(image: mainImage)
            showMainPhotoButton.isHidden = false
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL,
                     duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        videoUrl = outputFileURL
        savePhotoButton.isHidden = false
    }
}

extension CameraViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mainImageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Make sure the image in the scroll view is centered after each zoom action
        updateMainImageViewConstraints()
    }
}
