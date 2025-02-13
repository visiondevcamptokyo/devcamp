import SwiftUI
import Nostr
import SwiftData

struct StartView: View {
    
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            
            ZStack(alignment: .center) {
                Color.clear
                    .overlay(alignment: .top) {
                        Image("momiji_bg1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
            }
            .edgesIgnoringSafeArea(.all)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    
                    VStack(spacing: 2) {
                        Text("Welcome to VisionDevCamp Tokyo!")
                            .font(.system(size: 56, weight: .black))
                            .foregroundColor(.white)
                            .italic()
                        
                        Text("An online communication tool using Spatial Persona and SharePlay.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .offset(x: 0, y: -8)
                    }
                    .frame(maxWidth: .infinity)
                    
                    LazyVStack {
                        NavigationLink("Signin with Nostr Account", value: 0)
                            .buttonStyle(.borderedProminent)
                    }
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    LazyVStack {
                        Button(action: {
                            Task {
                                if let ownerAccount = OwnerAccount.createNew() {
                                    ownerAccount.selected = true
                                    modelContext.insert(ownerAccount)
                                    appState.selectedOwnerAccount = ownerAccount
                                    
                                    await addRelay()
                                    
                                    navigationPath.append(1)
                                } else {
                                    print("Failed to create OwnerAccount")
                                }
                            }
                        }) {
                            Text("Create an Account")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color.black)
            }
            .navigationDestination(for: Int.self) { value in
                switch value {
                case 0:
                    SigninView(navigationPath: $navigationPath)
                        .navigationBarBackButtonHidden()
                case 1:
                    SignupView(navigationPath: $navigationPath)
                        .navigationBarBackButtonHidden()
                default:
                    Text("Something went wrong...")
                }
            }
        }
    }
    
    private func addRelay() async {
        let metadataRelayUrl = "wss://relay.damus.io"
        let nip29relayUrl = "wss://groups.yugoatobe.com"
        
        if let metadataRelay = Relay.createNew(withUrl: metadataRelayUrl) {
            modelContext.insert(metadataRelay)
            do {
                try modelContext.save()
            } catch {
                print("Error saving metadataRelay: \(error)")
            }
            _ = await metadataRelay.updateRelayInfo()
            
            if !metadataRelay.supportsNip1 {
                print("This relay does not support Nip 1.")
                modelContext.delete(metadataRelay)
            }
        }
        
        if let nip29Relay = Relay.createNew(withUrl: nip29relayUrl) {
            modelContext.insert(nip29Relay)
            do {
                try modelContext.save()
            } catch {
                print("Error saving nip29Relay: \(error)")
            }
            _ = await nip29Relay.updateRelayInfo()
            
            if !nip29Relay.supportsNip29 {
                print("NO NIP 29")
                modelContext.delete(nip29Relay)
            }
        }
        
        await appState.setupYourOwnMetadata()
        await appState.subscribeGroupMetadata()
    }
}
