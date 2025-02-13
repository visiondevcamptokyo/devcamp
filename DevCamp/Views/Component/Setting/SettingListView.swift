import SwiftUI
import SwiftData

struct SettingListView: View {
    @Binding var selectedSetting: SettingItem?
    @State private var isShowingLogoutModal = false

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
                isShowingLogoutModal = true
            }) {
                Text("Logout")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $isShowingLogoutModal) {
            LogoutConfirmationView(isPresented: $isShowingLogoutModal)
        }
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
                    deleteAllData()
                    
                    appState.selectedOwnerAccount = nil
                    appState.selectedNip1Relay = nil
                    appState.selectedNip29Relay = nil
                    appState.registeredNsec = false
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
    
    private func deleteAllData() {
        do {
            let ownerAccounts = try modelContext.fetch(FetchDescriptor<OwnerAccount>())
            for account in ownerAccounts {
                modelContext.delete(account)
            }
            
            let relays = try modelContext.fetch(FetchDescriptor<Relay>())
            for relay in relays {
                modelContext.delete(relay)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }
}



