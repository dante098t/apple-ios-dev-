

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Cài đặt")
                .font(.largeTitle).bold()
            
            // ✅ Hiển thị tên user
            if authVM.userName != "" {
                Text("👤 Xin chào: \(authVM.userName)")
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            if let email = authVM.user?.email {
                Text("Email: \(email)")
                    .foregroundColor(.gray)
            }

            Button("Đăng xuất") {
                authVM.logout()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .navigationTitle("Cài đặt")
    }
}
