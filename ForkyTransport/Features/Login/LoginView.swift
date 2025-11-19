import SwiftUI

struct LoginView: View {
    
    @StateObject var viewModel: LoginViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ForkyTransport")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack {
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                Button(action: {
                    viewModel.login()
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
}
