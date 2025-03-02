import SwiftUI
import PhotosUI

struct SessionLinkView: View {
    @EnvironmentObject private var appState: AppState
    @State private var sheetDetailForAddSessionLink: InventoryItem?
    @State private var groupName: String = ""
    @State private var groupLink: String = ""
    @State private var maxMembers: String = ""
    @State private var groupDescription: String = ""
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var groupImage: String = ""
    
    private var isFaceTimeLinkValid: Bool {
        groupLink.hasPrefix("https://facetime")
    }
    
    var body: some View {
            
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
                    guard isFaceTimeLinkValid else {
                        print("誤った形式です")
                        return
                    }
                    
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
                                await appState.editGroupMetadata(ownerAccount: account, groupId: groupId, picture: groupImage, name: groupName, about: jsonAboutString)
                            } else {
                                let groupId = UUID().uuidString
                                appState.createdGroupMetadata = (ownerAccount: account, groupId: groupId, picture: groupImage, name: groupName, about: jsonAboutString)
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
                
                Spacer()

                if let url = URL(string: groupImage) {
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
                    
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.gray)
                            
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
                        .frame(width: 180, height: 180)
                    }
                }
                Spacer()
                
            }
            
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

        Spacer()
        
    }
    
    private func fetchAdminUserMetadata() -> [UserMetadata] {
        let adminPublicKeys = appState.allGroupAdmin
            .filter { $0.groupId == appState.selectedGroup?.id }
            .map { $0.publicKey }
        let adminMetadatas = appState.allUserMetadata.filter { user in
            adminPublicKeys.contains(user.publicKey)
        }
        return adminMetadatas
    }
}
