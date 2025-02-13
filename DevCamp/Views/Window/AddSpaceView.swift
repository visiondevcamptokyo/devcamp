import SwiftUI
import PhotosUI

/// A view that presents the group settings input.
struct AddSpaceView: View {
    @State private var groupName: String = ""
    @State private var maxMembers: String = ""
    @State private var groupDescription: String = ""
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var groupImage: Image? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Group Settings")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 20)
                
                Group {
                    Text("Group Name")
                        .font(.headline)
                    TextField("Enter group name", text: $groupName)
                        .padding()
                        .frame(width: 500)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Maximum Members")
                        .font(.headline)
                    TextField("Enter maximum members", text: $maxMembers)
                        .keyboardType(.numberPad)
                        .padding()
                        .frame(width: 500)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Group Description")
                        .font(.headline)
                    TextField("Enter group description", text: $groupDescription)
                        .lineLimit(5, reservesSpace: true)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Group Image")
                        .font(.headline)
                    
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        if let groupImage = groupImage {
                            groupImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                    }
                    .onChange(of: selectedImage) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                groupImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                }
                
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        print("Group settings saved")
                    }) {
                        Text("Save Group")
                            .font(.headline)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding()
                            .frame(width: 300)
                    }
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    Spacer()
                }
            }
            .padding()
        }
    }
}

