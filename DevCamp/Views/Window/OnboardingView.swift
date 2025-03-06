import SwiftUI

struct OnboardingView: View {
    @State private var currentPage: Int = 1

    var body: some View {
        VStack {
            Spacer()
            
            Text("ページ \(currentPage)")
                .font(.largeTitle)
                .padding()
            
            Spacer()
            
            HStack {
                Button("前へ") {
                    if currentPage > 1 {
                        currentPage -= 1
                    }
                }
                .padding()
                
                Spacer()
                
                Button("次へ") {
                    if currentPage < 4 {
                        currentPage += 1
                    }
                }
                .padding()
            }
            .padding(.horizontal)
        }
    }
}

