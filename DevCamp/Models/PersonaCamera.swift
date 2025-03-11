import Foundation
import AVFoundation
import UIKit
import CoreImage

class PersonaCamera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var callback: (UIImage) -> Void
    private var captureSession: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoDataOutputQueue: DispatchQueue?

    init(callback: @escaping (UIImage) -> Void) {
        self.callback = callback
        super.init()
    }

    @MainActor
    func setupCamera() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else { return }

        guard let camera = AVCaptureDevice.systemPreferredCamera else { return }

        guard let videoInput = try? AVCaptureDeviceInput(device: camera) else { return }

        let captureSession = AVCaptureSession()
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("Could not add video input")
            return
        }

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [
            (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)
        ]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        } else {
            print("Could not add video output")
            return
        }

        self.captureSession = captureSession
        self.videoDataOutput = videoDataOutput
        self.videoDataOutputQueue = videoDataOutputQueue

        captureSession.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let imageRect = CGRect(x: 0, y: 0, width: width, height: height)

        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: imageRect) else { return }

        DispatchQueue.main.async {
            self.callback(UIImage(cgImage: cgImage))
        }
    }
}
