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
                        NavigationLink("Create an Account", value: 1)
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
                case 2:
                    OnboardingView()
                        .navigationBarBackButtonHidden()
                default:
                    Text("Something went wrong...")
                }
            }
        }
    }
}
