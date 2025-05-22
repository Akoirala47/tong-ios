import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var isSignUp = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text(isSignUp ? "Sign Up" : "Sign In")
                .font(.largeTitle)
                .bold()
            TextField("Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            if isSignUp {
                Button(action: {
                    Task { await viewModel.signUpWithEmail() }
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button("Already have an account? Sign In") {
                    isSignUp = false
                }
                .font(.footnote)
            } else {
                Button(action: {
                    Task { 
                        print("Sign in button tapped")
                        await viewModel.signInWithPassword() 
                    }
                }) {
                    Text("Sign In with Password")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button("Don't have an account? Sign Up") {
                    isSignUp = true
                }
                .font(.footnote)
            }
        }
        .padding()
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
} 