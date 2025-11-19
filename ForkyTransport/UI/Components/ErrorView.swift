import SwiftUI

/// A simple, reusable view to display a prominent error message.
struct ErrorView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

#Preview {
    ErrorView(
        title: "Error de Base de Datos",
        message: "No se pudo inicializar la base de datos de la aplicación. Por favor, reinicia la aplicación."
    )
}
