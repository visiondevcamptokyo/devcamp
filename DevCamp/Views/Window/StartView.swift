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
                    
                    Text("By continuing to the next step, you agree to our End User License Agreement")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .onTapGesture {
                            navigationPath.append(3)
                    }
                    Spacer()
                        .frame(height: 5)
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
                case 3:
                    EULAView()
                case 4:
                    SetIconView()
                        .navigationBarBackButtonHidden()
                default:
                    Text("Something went wrong...")
                }
            }
        }
    }
}

struct EULAView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                Text("""
                    **End User License Agreement**
                    
                    
                    **Introduction**
                    This End User License Agreement ("EULA") is a legal agreement between you and us for the use of our mobile application devCamp. By installing, accessing, or using our application, you agree to be bound by the terms and conditions of this EULA.

                    **1. Prohibited Content and Conduct**
                    You agree not to use our application to create, upload, post, send, or store any content that:

                        • Is illegal, infringing, or fraudulent
                        • Is defamatory, libelous, or threatening
                        • Is pornographic, obscene, or offensive
                        • Is discriminatory or promotes hate speech
                        • Is harmful to minors
                        • Is intended to harass or bully others
                        • Is intended to impersonate others
                    
                    **2. You also agree not to engage in any conduct that:**
                        • Harasses or bullies others
                        • Impersonates others
                        • Is intended to intimidate or threaten others
                        • Is intended to promote or incite violence
                    
                    **3. Consequences of Violation**
                    Any violation of this EULA, including the prohibited content and conduct outlined above, may result in the termination of your access to our application.
                    
                    **4. third party services and links**
                    This application may contain links to services or websites provided by third parties. We are not responsible for the content, quality, or terms of use of these third party services. Users use third party services at their own risk.
                    
                    **5. user liability and indemnification (indemnification)**
                    You agree to settle any claims, damages, lawsuits, etc. from third parties arising from your use of this application at your own responsibility and expense, and agree to indemnify and hold us harmless from any such claims, damages, lawsuits, etc.
                    

                    **6. Disclaimer of Warranties and Limitation of Liability**
                    Our application is provided "as is" and "as available" without warranty of any kind, either express or implied, including but not limited to the implied warranties of merchantability and fitness for a particular purpose. We do not guarantee that our application will be uninterrupted or error-free. In no event shall we be liable for any damages whatsoever, including but not limited to direct, indirect, special, incidental, or consequential damages, arising out of or in connection with the use or inability to use our application.
                    
                    **7. separability**
                    If any provision of this EULA is held invalid or unenforceable, the other provisions will remain in full force and effect.

                    **8. Changes to EULA**
                    We reserve the right to update or modify this EULA at any time and without prior notice. Your continued use of our application following any changes to this EULA will be deemed to be your acceptance of such changes.

                    **9. Contact Information**
                    If you have any questions about this EULA, please contact us at yugoatobe0330@gmail.com

                    **10. Acceptance of Terms**
                    By using our Application, you signify your acceptance of this EULA. If you do not agree to this EULA, you may not use our Application.
                    """)
                .padding()
            }
            .frame(maxWidth: 800)
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("End User License Agreement")
        .navigationBarTitleDisplayMode(.inline)
    }
}

