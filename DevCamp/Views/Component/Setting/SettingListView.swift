import SwiftUI
import SwiftData

struct SettingListView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedSetting: SettingItem?
    @State private var isShowingLogoutModal = false
    @State private var isShowingDeleteAccountModal = false

    var body: some View {
        VStack {
            List(SettingItem.allCases, id: \.self, selection: $selectedSetting) { item in
                NavigationLink(value: item) {
                    Label(item.label, systemImage: item.iconName)
                }
            }
            .navigationTitle("Settings")
            
            Spacer()

            Button(action: {
                Task {
                    await resetState()
                    await appState.setupYourOwnMetadata()
                    await appState.subscribeGroupMetadata()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .imageScale(.medium)
                    
                    Text("Reload")
                        .font(.body)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            Button(action: {
                isShowingLogoutModal = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .imageScale(.medium)
                    
                    Text("Logout")
                        .font(.body)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            Button(action: {
                 isShowingDeleteAccountModal = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .imageScale(.medium)
                    
                    Text("Delete Account")
                        .font(.body)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 20)

        }
        .sheet(isPresented: $isShowingLogoutModal) {
            LogoutConfirmationView(isPresented: $isShowingLogoutModal)
        }
        .sheet(isPresented: $isShowingDeleteAccountModal){
            DeleteConfirmationView(isPresented: $isShowingDeleteAccountModal)
        }
    }
    
    private func resetState() async {
        do {
            let relays = try modelContext.fetch(FetchDescriptor<Relay>());
            let relaysUrl = relays.map(\.url)
            appState.remove(relaysWithUrl: relaysUrl)
        } catch {
            print("Failed to fetch relays: \(error)")
        }
        
        appState.lastEditGroupMetadataEventId = nil
        appState.lastCreateGroupMetadataEventId = nil
        appState.createdGroupMetadata = (ownerAccount: nil, groupId: nil, picture: nil, name: nil, about: nil)
        appState.isSheetPresented = false
        appState.selectedOwnerAccount = nil
        appState.selectedNip1Relays = []
        appState.selectedNip29Relay = nil
        appState.selectedGroup = nil
        appState.selectedEditingGroup = nil
        appState.allChatGroup = []
        appState.allChatMessage = []
        appState.allUserMetadata = []
        appState.allGroupAdmin = []
        appState.allGroupMember = []
        appState.chatMessageNumResults = 50
        appState.statuses = [:]
        appState.ownerPostContents = []
        appState.profileMetadata = nil
    }
}

struct LogoutConfirmationView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 20) {
            Text("Make sure you have saved your nsec private key before logging out. If you have not saved it, you will lose access to your account.")
                .multilineTextAlignment(.center)
                .padding()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding()
                .cornerRadius(5)

                Button("Logout") {
                    do {
                        let relays = try modelContext.fetch(FetchDescriptor<Relay>());
                        let relaysUrl = relays.map(\.url)
                        appState.remove(relaysWithUrl: relaysUrl)
                    } catch {
                        print("Failed to fetch relays: \(error)")
                    }
                    
                    appState.deleteAllSwiftData(modelContext: modelContext)
                    
                    appState.resetState()
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .cornerRadius(5)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 300)
    }
    
    
    
    
}

struct DeleteConfirmationView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var confirmationText: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Are you sure you want to delete your account? \n Once you delete it, you will never be able to restore it again.")
                .multilineTextAlignment(.center)
                .padding()
            
            TextField("Type DELETE to confirm", text: $confirmationText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding()
                .cornerRadius(5)
                
                Button("Delete") {
                    deleteAccount()
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .cornerRadius(5)
                .disabled(confirmationText != "DELETE")
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 400)
    }
    
    private func deleteAccount() {
        
        appState.deleteUserMetadata()
        appState.lastDeleteUserMetadataModelContext = modelContext
        
        isPresented = false
    }
}


