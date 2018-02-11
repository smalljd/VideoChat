//
//  ViewController.swift
//  VideoChat
//
//  Created by Jeff on 2/3/18.
//  Copyright © 2018 Jeff Small. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation
import VideoToolbox

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var recordButton: NSButton!

    var isRecording = false

    // Video capture
    let captureQueue = DispatchQueue(label: "CaptureQueue", qos: .default)
    var videoOutput: AVCaptureVideoDataOutput?
    let videoSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?

    @IBOutlet weak var mainContentView: NSView!
    @IBOutlet weak var videoPreviewView: NSView!

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func didTapRecordButton(_ sender: Any) {
        isRecording = !isRecording
        isRecording ? (recordButton.title = "Stop") : (recordButton.title = "Record")
        isRecording ? startRecording() : stopRecording()
    }

    func startRecording() {
        videoSession.sessionPreset = .medium
        addInput()
        addOutput()
        videoSession.startRunning()
    }

    func addInput() {
        if let inputDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: inputDevice),
            videoSession.canAddInput(videoInput)
        {
            videoSession.addInput(videoInput)
            addPreviewLayer()
        }
    }

    func addOutput() {
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: captureQueue)

        if let videoOutput = videoOutput, videoSession.canAddOutput(videoOutput) {
            videoSession.addOutput(videoOutput)
        }
    }

    func stopRecording() {
        videoSession.stopRunning()
        VTCompressionSessionCompleteFrames(VideoCompression.default.compressionSession!, CMTimeMake(0, 1))
        VTCompressionSessionInvalidate(VideoCompression.default.compressionSession!)
    }

    func addPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: videoSession)
        previewLayer?.videoGravity = .resizeAspectFill

        if videoPreviewView.layer == nil {
            videoPreviewView.layer = CALayer()
        }

        previewLayer?.frame = videoPreviewView.bounds
        videoPreviewView.layer?.addSublayer(previewLayer!)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Compress frames and convert to NSData
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Couldn't make pixel buffer")
            return
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        VideoCompression.default.createSession(width: Int32(width), height: Int32(height))

        guard VideoCompression.default.status == noErr, let session = VideoCompression.default.compressionSession else {
            assertionFailure("Couldn't create video session")
            return
        }

        VTSessionSetProperty(videoSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue)
        let presentationTimeStamp = CMTimeMake(0, 1)
        VTCompressionSessionEncodeFrame(session, pixelBuffer, presentationTimeStamp,
                                        kCMTimeInvalid, nil, nil, nil)
        var darwinBoolean = DarwinBoolean(false)

        VTCompressionSessionEndPass(session, &darwinBoolean, nil)
        VTCompressionSessionInvalidate(session)
    }
}

