import SwiftUI

struct PersonaCameraView: View {
    @State private var personaCamera: PersonaCamera?
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = self.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 400, height: 400)
                    .clipped()
            } else {
                ProgressView("Loading camera...")
            }
        }
        .onAppear {
            personaCamera = PersonaCamera(callback: { image in
                self.image = image
            })
            Task {
                await personaCamera?.setupCamera()
            }
        }
    }
}

struct PersonaCameraViewWrapper: View {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var personaCamera: PersonaCamera? = nil
    @State private var image: UIImage? = nil

    private func cropToSquare(_ uiImage: UIImage) -> UIImage? {
        let originalWidth = uiImage.size.width
        let originalHeight = uiImage.size.height
        let side = min(originalWidth, originalHeight)
        let x = (originalWidth - side) / 2.0
        let y = (originalHeight - side) / 2.0
        let cropRect = CGRect(x: x, y: y, width: side, height: side)
        guard let cgImage = uiImage.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: uiImage.scale, orientation: uiImage.imageOrientation)
    }

    var body: some View {
        ZStack {
            if let image = self.image {
                if let squareImage = cropToSquare(image) {
                    Image(uiImage: squareImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipped()
                        .cornerRadius(32)
                }
            } else {
                ProgressView("Loading camera...")
            }
        }
        .padding(32)
        .onAppear {
            personaCamera = PersonaCamera(callback: { capturedImage in
                if let squareImage = cropToSquare(capturedImage) {
                    self.image = squareImage
                } else {
                    self.image = capturedImage
                }
            })
            Task {
                await personaCamera?.setupCamera()
            }
        }
        VStack {
            HStack {
                Button("Capture") {
                    if let confirmedImage = image {
                        onCapture(confirmedImage)
                        dismiss()
                    }
                }
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
        }
    }
}
