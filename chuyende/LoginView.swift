import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showResend = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Text("Đăng nhập")
                    .font(.largeTitle).bold()
                
                // Trường nhập
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Mật khẩu", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Nút login
                Button {
                    loginAction()
                } label: {
                    Text(isLoading ? "Đang xử lý..." : "Đăng nhập")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                Button {
                    // Chưa cần thực hiện gì
                } label: {
                    HStack {
                        Image(systemName: "faceid")
                            .font(.title2)
                        Text("Đăng nhập bằng FaceID")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                // Gửi lại email verify
                if showResend {
                    Button(" Gửi lại email xác minh") {
                        if let user = Auth.auth().currentUser {
                            user.sendEmailVerification { error in
                                alertMessage = error?.localizedDescription ?? "Đã gửi email xác minh."
                                showAlert = true
                            }
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Link sang đăng ký
                NavigationLink("Chưa có tài khoản? Đăng ký") {
                    RegisterView().environmentObject(authVM)
                }
            }
            .padding()
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    // Xử lý login
    func loginAction() {
        isLoading = true
        authVM.login(email: email, password: password) { success, message in
            isLoading = false
            if success {
                if let user = Auth.auth().currentUser {
                    if user.isEmailVerified {
                        authVM.saveLoginInfo(email: email, password: password)
                        authVM.user = user
                        print(" Đăng nhập thành công → vào HomeView / AdminHomeView")
                    } else {
                        alertMessage = "Vui lòng xác minh email trước khi đăng nhập."
                        showAlert = true
                        showResend = true
                        try? Auth.auth().signOut()   // 👉 signOut nếu chưa verify
                        authVM.user = nil
                    }
                }
            } else {
                alertMessage = message ?? " Đăng nhập thất bại."
                showAlert = true
                showResend = message?.contains("xác minh") == true
            }
        }
    }
}
