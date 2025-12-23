import SwiftUI
import CoreData

struct WelcomeView: View {
    @Binding var isActive: Bool
    
    var body: some View {
        ZStack {
            // Reusing the background animation
            BackgroundAnimationView()
                .opacity(0.8) // High opacity for vibrancy on welcome screen
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("ScriptureSketch")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isActive = false
                    }
                }) {
                    Text("Start Cataloging")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .shadow(radius: 5)
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    WelcomeView(isActive: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
