import SwiftUI

struct OnboardingView: View {
    @State private var currentPage: Int = 1
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            VStack {
                Spacer()
                
                VStack {
                    VStack {
                        Text(titleText(for: currentPage))
                            .font(.largeTitle)
                            .padding(.top, 50)
                            .padding(.bottom, 8)
                        
                        Text(contentText(for: currentPage))
                            .font(.headline)
                        if currentPage == 5 {
                            Link("devcamp.social", destination: URL(string: "https://devcamp.social")!)
                                .padding(.bottom, 24)
                        } else {
                            Text("")
                                .padding(.bottom, 24)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    
                    Image("Onboarding\(currentPage)")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 800)
                }
                
                Spacer()
                
                HStack(spacing: 40) {
                    Button("Back") {
                        if currentPage > 1 {
                            currentPage -= 1
                        }
                    }
                    .disabled(currentPage == 1)
                    .padding()
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \ .self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.black : Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Button(currentPage < 5 ? "Next" : "End") {
                        if currentPage < 5 {
                            currentPage += 1
                        } else {
                            appState.registeredNsec = true
                        }
                    }
                    .frame(width: 100)
                    .padding(.bottom)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.clear)
                .multilineTextAlignment(.center)
            }
            
            Image("DevCamp")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .padding([.top, .leading], 16)
            
            HStack {
                Spacer()
                Button("Skip") {
                    appState.registeredNsec = true
                }
                .frame(width: 100)
                .padding()
            }
            .padding([.top, .trailing], 16)
        }
    }
    
    private func titleText(for page: Int) -> String {
        switch page {
        case 1: return "Start FaceTime"
        case 2: return "Start FaceTime"
        case 3: return "Create a session"
        case 4: return "Public and private key storage"
        case 5: return "More detailed description"
        default: return ""
        }
    }
    
    private func contentText(for page: Int) -> String {
        switch page {
        case 1: return "Select the session you want to enter."
        case 2: return "Press the FaceTime button and you can start FaceTime."
        case 3: return "You can create a session by pressing the ”Create Session” button on the home screen."
        case 4: return "Copy and save the public and private keys from the settings screen. Otherwise, this account cannot be restored."
        case 5: return "If you want to see more information, open this link!"
        default: return ""
        }
    }
}
