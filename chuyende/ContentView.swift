import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        Group {
            if let user = authVM.user {
                if !user.isEmailVerified {
                    VerifyEmailView()
                } else {
                    if authVM.role == "admin" {
                        AdminHomeView()
                    } else {
                        HomeView()
                    }
                }
            } else {
                // 👉 Mặc định hiển thị Login
                LoginView()
            }
        }
        .onAppear {
            // 🚨 Bắt buộc logout khi mở app
            do {
                try Auth.auth().signOut()
                authVM.user = nil
                authVM.isAuthenticated = false
                print("🔴 Reset phiên đăng nhập → luôn vào LoginView")
            } catch {
                print("❌ Logout khi mở app lỗi: \(error.localizedDescription)")
            }
        }
    }
}   
