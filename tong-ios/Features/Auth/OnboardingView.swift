import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAuthView = false

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                // App Logo
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.bottom, 40)
                
                Text("Welcome to Tong!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                Text("Your language learning journey starts here.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)

                Spacer()

                // Get Started Button
                Button(action: {
                    showAuthView = true
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                
                // For debugging - quick login
                Button(action: {
                    // Set demo credentials
                    authViewModel.email = "demo@example.com"
                    authViewModel.password = "password123"
                    
                    // Attempt sign in
                    Task {
                        await authViewModel.signInWithPassword()
                    }
                }) {
                    Text("Debug Login")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
                .padding(.bottom, 60)
            }
            .fullScreenCover(isPresented: $showAuthView) {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AuthViewModel())
    }
} 