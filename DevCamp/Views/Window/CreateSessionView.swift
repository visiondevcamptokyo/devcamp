import SwiftUI
import PhotosUI

struct CreateSessionView: View {
    @EnvironmentObject private var appState: AppState
    @State private var groupName: String = ""
    @State private var maxMembers: String = ""
    @State private var groupDescription: String = ""
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var groupImage: Image? = nil
    @State private var sheetDetailForSessionLink: InventoryItem?
    @Binding var sheetDetail: InventoryItem?
    
    var body: some View {
        
        GeometryReader { geometry in
            
            VStack(alignment: .leading, spacing: 20) {
                
                HStack {
                    Button(action: {
                        sheetDetail = nil
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 15, height: 15)
                    }
                    .frame(width: 15, height: 15)
                    .contentShape(Circle())
                    .padding(.leading, 30)
                    .padding(.bottom)
                    
                    
                    Spacer()
                    
                    Text("Create a Session")
                        .font(.title)
                        .padding(.bottom, 20)
                        .padding(.trailing, 50)
                    
                    Spacer()
                    
                }
                .padding(.top, 10)
                
                Button(action: {
                    sheetDetailForSessionLink = InventoryItem(
                        id: "0123456789",
                        partNumber: "Z-1234A",
                        quantity: 100,
                        name: "Widget"
                    )
                }) {
                    HStack {
                        ZStack {
                            Rectangle()
                                .fill(Material.thin)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                        
                        Text("New Group")
                            .padding(.leading, 8)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(item: $sheetDetailForSessionLink) { detail in
                    VStack(alignment: .leading, spacing: 20) {
                        SessionLinkView(sheetDetail: $sheetDetailForSessionLink)
                    }
                    .presentationDetents([
                        .large,
                        .height(300),
                        .fraction(1.0),
                    ])
                }
                
                
                
                Text("All Groups of which you are the administrator")
                    .font(.headline)
                    .padding(.leading, 30)
                
                ForEach(appState.allChatGroup.filter({$0.isAdmin }), id: \.id) { group in
                    Button(action: {
                        appState.selectedEditingGroup = group
                        sheetDetailForSessionLink = InventoryItem(
                            id: "0123456789",
                            partNumber: "Z-1234A",
                            quantity: 100,
                            name: "Widget"
                        )
                    }) {
                        HStack {
                            if let pictureURL = group.picture,
                               let url = URL(string: pictureURL) {
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
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            }
                            
                            Text(group.name ?? "")
                                .padding(.leading, 8)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(item: $sheetDetailForSessionLink) { detail in
                        VStack(alignment: .leading, spacing: 20) {
                            SessionLinkView(sheetDetail: $sheetDetailForSessionLink)
                        }
                        .presentationDetents([
                            .large,
                            .height(300),
                            .fraction(1.0),
                        ])
                    }
                }
                Spacer()
                
            }
            .padding()
            
        }
        .onReceive(appState.$shouldCloseEditSessionLinkSheet) { shouldClose in
            if shouldClose {
                sheetDetail = nil
                appState.shouldCloseEditSessionLinkSheet = false
            }
        }
    }
}
