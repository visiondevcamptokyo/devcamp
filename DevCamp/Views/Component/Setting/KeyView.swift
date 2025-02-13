import SwiftUI
import Nostr
import KeychainAccess
import LocalAuthentication

struct KeyView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showPrivateKey = false
    @State private var showCopiedMessage = false
    @State private var publicKey = ""
    @State private var privateKey = ""

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Keys")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Public Key")
                            .font(.headline)
                        HStack {
                            Button(action: {
                                UIPasteboard.general.string = publicKey
                                showCopyMessage()
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            
                            Text(publicKey)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Private Key")
                            .font(.headline)
                        HStack {
                            Button(action: {
                                UIPasteboard.general.string = privateKey
                                showCopyMessage()
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            Text(showPrivateKey ? (privateKey) : String(repeating: "•", count: privateKey.count))
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .contextMenu {
                                    if showPrivateKey {
                                        Button {
                                            UIPasteboard.general.string = appState.selectedOwnerAccount?.publicKey ?? ""
                                            showCopyMessage()
                                        } label: {
                                            Label("Copy Private Key", systemImage: "doc.on.doc")
                                        }
                                    }
                                }
                            Button(action: {
                                if !showPrivateKey {
                                    let context = LAContext()
                                    var error: NSError?
                                    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                                        let reason = "プライベートキーを表示するために認証してください。"
                                        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                                            DispatchQueue.main.async {
                                                if success {
                                                    withAnimation {
                                                        showPrivateKey = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    withAnimation {
                                        showPrivateKey = false
                                    }
                                }
                            }) {
                                Image(systemName: showPrivateKey ? "eye.slash" : "eye")
                                    .foregroundColor(.blue)
                            }

                            .buttonStyle(.plain)
                        }
                    }
                    
                    Spacer()
                }
                .padding(32)
            }
            .onAppear {
                getKeypair()
            }
            
            if showCopiedMessage {
                VStack {
                    Spacer()
                    Text("Copied!")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    Spacer().frame(height: 40)
                }
                .transition(.opacity)
            }
        }
    }
    
    private func showCopyMessage() {
        withAnimation {
            showCopiedMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
    }

    private func getKeypair() {
        let keychain = Keychain(service: "devcamp")
        guard let privateKeyData = try? keychain.get(appState.selectedOwnerAccount?.publicKey ?? "") else { return }
        
        if let privateKeyPair = try? KeyPair(hex: privateKeyData) {
            publicKey = privateKeyPair.bech32PublicKey
            privateKey = privateKeyPair.bech32PrivateKey
        }
    }
}


