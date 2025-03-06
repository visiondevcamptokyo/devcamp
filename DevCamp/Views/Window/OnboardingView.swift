import SwiftUI

struct OnboardingView: View {
    @State private var currentPage: Int = 1
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                Image("Test\(currentPage)")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                
                Text("このページ\(currentPage)はまだ実装していない画面です。")
                    .font(.headline)
                    .padding(.top, 8)
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
                
                Button(currentPage < 4 ? "Next" : "End") {
                    if currentPage < 4 {
                        currentPage += 1
                    } else {
                        appState.registeredNsec = true
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.clear)
            .multilineTextAlignment(.center)
        }
    }
}

