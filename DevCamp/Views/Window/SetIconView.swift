import SwiftUI

struct SetIconView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var personaCamera: PersonaCamera? = nil
    @State private var image: UIImage? = nil
    @State private var isUploadingImage = false
    @EnvironmentObject var appState: AppState

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
            // カメラプレビューまたは撮影した画像を表示
            if let capturedImage = image {
                // 画像を表示
                if let squareImage = cropToSquare(capturedImage) {
                    Image(uiImage: squareImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipped()
                        .cornerRadius(32)
                }
            } else {
                // カメラ起動前/起動中のロード表示
                ProgressView("Loading camera...")
            }
        }
        .padding(32)
        .onAppear {
            // カメラセットアップ
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
            Spacer()
            HStack {
                if let confirmedImage = image {
                    // 画像があるので再撮影または保存
                    Button("Retake") {
                        // 再度撮り直す場合は image を nil にしてカメラプレビュー表示を戻す
                        image = nil
                    }
                    .padding()

                    Button("Save") {
                        // サーバー等にアップロード
                        isUploadingImage = true
                        Task {
                            do {
                                guard let data = confirmedImage.jpegData(compressionQuality: 0.8) else {
                                    print("Could not convert UIImage to Data.")
                                    isUploadingImage = false
                                    return
                                }
                                
                                let fileExtension = "jpg"
                                if let urlString = try await appState.setPicture(fileData: data, fileExtension: fileExtension) {
                                    DispatchQueue.main.async {
                                        appState.profileMetadata?.picture = urlString
                                    }
                                } else {
                                    print("Could not parse URL.")
                                }
                            } catch {
                                print("Error during uploading image: \\(error)")
                            }
                            isUploadingImage = false
                            dismiss()
                        }
                    }
                    .padding()
                } else {
                    // まだ写真を撮っていない状態 -> 撮影ボタン
                    Button("Take Photo") {
                        isUploadingImage = true
                        if let confirmedImage = image {
                            Task {
                                do {
                                    guard let data = confirmedImage.jpegData(compressionQuality: 0.8) else {
                                        print("Could not convert UIImage to Data.")
                                        isUploadingImage = false
                                        return
                                    }
                                    
                                    let fileExtension = "jpg"
                                    if let urlString = try await appState.setPicture(fileData: data, fileExtension: fileExtension) {
                                        DispatchQueue.main.async {
                                            appState.profileMetadata?.picture = urlString
                                        }
                                    } else {
                                        print("Could not parse URL.")
                                    }
                                } catch {
                                    print("Error during uploading image: \(error)")
                                }
                                isUploadingImage = false
                            }
                            dismiss()
                        }
                        
                    }
                    .padding()

                    Button("Close") {
                        dismiss()
                    }
                    .padding()
                }
            }
            .padding(.bottom)
        }
        .overlay {
            if isUploadingImage {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("Uploading image...")
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                }
            }
        }
    }
}
