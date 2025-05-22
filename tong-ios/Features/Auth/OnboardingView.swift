import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Assuming AuthViewModel is needed

    var body: some View {
        VStack {
            Text("Welcome to Tong!")
                .font(.largeTitle)
                .padding()
            
            Text("Your language learning journey starts here.")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()

            // Example Button to navigate to AuthView or similar
            Button(action: {
                // This action would typically navigate to a sign-in/sign-up view.
                // For now, it can just print a message or try to set a flag in authViewModel.
                print("Proceed from Onboarding tapped")
                // authViewModel.showAuthView = true // Example state change
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Onboarding")
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AuthViewModel()) // Provide a mock AuthViewModel for preview
    }
} 