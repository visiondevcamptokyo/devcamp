import SwiftUI
import PhotosUI
import SwiftData
import KeychainAccess
import Nostr
import UniformTypeIdentifiers


struct ProfileView: View {
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showSuccessAlert: Bool = false
    @State private var isUploadingImage = false

    @EnvironmentObject private var appState : AppState
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 20){
                Text("Account Settings")
                    .font(.largeTitle.bold())
                
                Group {
                    HStack(alignment: .center, spacing: 30) {
                        if isUploadingImage {
                            ProgressView()
                                .frame(width: 200, height: 200)
                        } else {
                            if let picture = appState.profileMetadata?.picture,
                               let url = URL(string: picture) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 200, height: 200)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 200, height: 200)
                                    case .failure(_):
                                        Text("No Image")
                                            .frame(width: 200, height: 200)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                    @unknown default:
                                        Text("Unknown status")
                                            .frame(width: 200, height: 200)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                }
                                .onTapGesture {
                                    showingImagePicker = true
                                }
                            } else {
                                Text("No Image")
                                    .frame(width: 200, height: 200)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        showingImagePicker = true
                                    }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Image URL")
                                .font(.headline)
                            
                            TextField("Enter image URL", text: Binding(
                                get: { appState.profileMetadata?.picture ?? "" },
                                set: { appState.profileMetadata?.picture = $0 }
                            ))
                                .padding()
                                .frame(width: 500)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }

                    }
                                        
                    Text("Public Key")
                        .font(.headline)
                    if let npubkey = try? appState.profileMetadata?.pubkey.bech32FromHex(hrp: "npub") {
                        Text(npubkey)
                    } else {
                        Text("No public key available")
                            .foregroundColor(.red)
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                    }
                    
                    Text("Name")
                        .font(.headline)
                    TextField("Enter account name", text: Binding(
                        get: { appState.profileMetadata?.displayName ?? "" },
                        set: { appState.profileMetadata?.displayName = $0 }
                    ))
                        .padding()
                        .frame(width:300)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("About")
                        .font(.headline)
                    TextField("Write something about yourself", text: Binding(
                        get: { appState.profileMetadata?.about ?? "" },
                        set: { appState.profileMetadata?.about = $0 }
                    ))
                        .lineLimit(5, reservesSpace: true)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        Task{
                            await appState.editUserMetadata(
                                name: appState.profileMetadata?.name,
                                about: appState.profileMetadata?.about,
                                picture: appState.profileMetadata?.picture,
                                nip05: appState.profileMetadata?.nip05,
                                displayName: appState.profileMetadata?.displayName,
                                website: appState.profileMetadata?.website,
                                banner: appState.profileMetadata?.banner,
                                bot: appState.profileMetadata?.bot,
                                lud16: appState.profileMetadata?.lud16
                            )
                        }
                        showSuccessAlert = true
                    }) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding()
                            .frame(width: 300)
                    }
                    .cornerRadius(12)
                    
                    Spacer()
                }
            }
            .padding(32)
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedItem,
            matching: .images,
            preferredItemEncoding: .automatic,
            photoLibrary: .shared()
        )
        .onChange(of: selectedItem) {
            isUploadingImage = true
            
            guard let newValue = selectedItem else {
                print("Can't select image")
                isUploadingImage = false
                return }
            
            let contentType = newValue.supportedContentTypes.first
            let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"

            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    selectedImageData = data
                    do {
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
                }
                
                isUploadingImage = false
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Metadata was successfully saved.")
        }
    }
}
