import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var role = "user" // default

    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showRolePicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin")) {
                    TextField("Tên hiển thị", text: $name)
                        .autocapitalization(.words)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Mật khẩu", text: $password)
                    SecureField("Nhập lại mật khẩu", text: $confirmPassword)
                }

                Section {
                    Button("Vai trò: \(role.capitalized)") {
                        showRolePicker = true
                    }
                }

                Section {
                    Button {
                        submitRegister()
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Đăng ký")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                }
            }
            .navigationTitle("Đăng ký")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Huỷ") { dismiss() }
                }
            }
            .confirmationDialog("Chọn vai trò", isPresented: $showRolePicker, titleVisibility: .visible) {
                Button("User") { role = "user" }
                Button("Admin") { role = "admin" }
                Button("Huỷ", role: .cancel) {}
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK") {
                    // Nếu đăng ký thành công (thông báo có chứa từ "xác minh"), dismiss về Login
                    if alertMessage.contains("xác minh") || alertMessage.contains("thành công") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func submitRegister() {
        // validate
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Vui lòng nhập tên."
            showAlert = true
            return
        }
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Vui lòng nhập email."
            showAlert = true
            return
        }
        guard password == confirmPassword else {
            alertMessage = "Mật khẩu không khớp."
            showAlert = true
            return
        }
        guard password.count >= 6 else {
            alertMessage = "Mật khẩu phải ít nhất 6 ký tự."
            showAlert = true
            return
        }

        isLoading = true

        // Gọi AuthViewModel.register có completion
        authVM.register(email: email, password: password, name: name, role: role) { success, message in
            DispatchQueue.main.async {
                self.isLoading = false
                self.alertMessage = message ?? (success ? "Đăng ký thành công. Vui lòng kiểm tra email để xác minh." : "Đăng ký thất bại.")
                self.showAlert = true
                // nếu success, dismiss sẽ được xử lý trong Alert OK action
            }
        }
    }
}

