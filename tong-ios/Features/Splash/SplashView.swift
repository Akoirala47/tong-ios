import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.white)
            
            }
            .scaleEffect(isActive ? 1.0 : 0.9)
            .opacity(isActive ? 1.0 : 0.5)
            .animation(.easeIn(duration: 1.2), value: isActive)
        }
        .onAppear {
            // Animate logo
            isActive = true
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AuthViewModel())
} 
