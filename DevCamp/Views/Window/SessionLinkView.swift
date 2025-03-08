import SwiftUI
import PhotosUI
import SwiftData
import KeychainAccess
import Nostr
import UniformTypeIdentifiers

struct SessionLinkView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var groupName: String = ""
    @State private var groupLink: String = ""
    @State private var maxMembers: String = ""
    @State private var groupDescription: String = ""
    
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var groupImage: String = ""
    
    @State private var isUploadingImage: Bool = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 20) {
                
                HStack {
                    Button(action: {
                        appState.isSheetPresented = false
                        appState.selectedEditingGroup = nil
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 15, height: 15)
                            .padding(10)
                    }
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
                    .padding(.leading, 30)
                    .padding(.bottom)
                    
                    Spacer()
                    
                    Text("Create a Session")
                        .font(.title)
                        .padding(.bottom, 20)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        guard isFaceTimeLinkValid else { return }
                        
                        appState.isCreateLoading = true
                        Task {
                            guard let account = appState.selectedOwnerAccount else {
                                print("ownerAccount not set")
                                return
                            }
                            let aboutData: [String: String] = [
                                "description": groupDescription,
                                "link": groupLink
                            ]
                            if let jsonAboutData = try? JSONEncoder().encode(aboutData),
                               let jsonAboutString = String(data: jsonAboutData, encoding: .utf8) {
                                
                                if let groupId = appState.selectedEditingGroup?.id {
                                    await appState.editGroupMetadata(
                                        ownerAccount: account,
                                        groupId: groupId,
                                        picture: groupImage,
                                        name: groupName,
                                        about: jsonAboutString
                                    )
                                } else {
                                    let groupId = UUID().uuidString
                                    appState.createdGroupMetadata = (
                                        ownerAccount: account,
                                        groupId: groupId,
                                        picture: groupImage,
                                        name: groupName,
                                        about: jsonAboutString
                                    )
                                    await appState.createGroup(ownerAccount: account, groupId: groupId)
                                }
                            }
                        }
                    }) {
                        Text("Create")
                    }
                    .padding(.bottom)
                }
                .padding(.top, 10)
                
                HStack {
                    
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        ZStack {
                            if isUploadingImage {
                                ProgressView("Uploading...")
                                    .frame(width: 180, height: 180)
                            } else if let url = URL(string: groupImage), !groupImage.isEmpty {
                                // 画像がある場合は表示
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                    @unknown default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                    }
                                }
                                .frame(width: 180, height: 180)
                                .clipShape(Circle())
                            } else {
                                Rectangle()
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.gray)
                                    .frame(width: 180, height: 180)
                                
                                VStack {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                    
                                    Text("Add Image")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .frame(width: 180, height: 180)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image URL")
                            .font(.headline)
                        TextField("https://...", text: $groupImage)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.leading, 50)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Session Title")
                        .font(.headline)
                    TextField("ex. Anyone can join!", text: $groupName)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Session Description")
                        .font(.headline)
                    TextField("ex. This is a room for VisionDevCamp", text: $groupDescription)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Session Link")
                        .font(.headline)
                    TextField("ex. https://...", text: $groupLink)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    if !isFaceTimeLinkValid && !groupLink.isEmpty {
                        Text(verbatim: "The link must begin with “https://facetime”.")
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 60)
                .padding(.trailing, 60)
                
                Spacer()
            }
            .padding()
            .onAppear {
                if let groupMetadata = appState.selectedEditingGroup {
                    groupImage = groupMetadata.picture ?? ""
                    groupName = groupMetadata.name ?? ""
                    groupDescription = groupMetadata.about ?? ""
                    groupLink = groupMetadata.facetime ?? ""
                }
            }
            
            if appState.isCreateLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    ProgressView("Loading...")
                        .padding()
                        .cornerRadius(10)
                }
            }
        }
        .onChange(of: selectedImage) {
            guard let newItem = selectedImage else { return }
            
            isUploadingImage = true
            
            let contentType = newItem.supportedContentTypes.first
            let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
            
            Task {
                do {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let uploadedUrlString = try await appState.setPicture(fileData: data, fileExtension: fileExtension) {
                            groupImage = uploadedUrlString
                        } else {
                            print("URLをパースできませんでした")
                        }
                    }
                } catch {
                    print("アップロード中にエラーが発生:", error)
                }
                isUploadingImage = false
            }
        }
    }
    
    private var isFaceTimeLinkValid: Bool {
        groupLink.hasPrefix("https://facetime") || groupLink.isEmpty
    }
}
