import SwiftUI
import FirebaseAuth

struct VerifyEmailView: View {
    @Environment(\.dismiss) var dismiss   // Dùng để quay lại màn hình trước
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Xác minh Email")
                .font(.title)
                .bold()
            
            Text("Vui lòng kiểm tra hộp thư và xác minh email trước khi tiếp tục.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Gửi lại email xác minh") {
                if let user = Auth.auth().currentUser {
                    user.sendEmailVerification { error in
                        if let error = error {
                            print(" Lỗi gửi lại email: \(error.localizedDescription)")
                        } else {
                            print(" Đã gửi lại email xác minh.")
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            // 🔹 Nút quay lại LoginView
            Button("Quay lại đăng nhập") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .tint(.gray)
            .padding(.top, 10)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}
