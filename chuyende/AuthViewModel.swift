import Foundation
import FirebaseAuth
import FirebaseFirestore
import LocalAuthentication

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var role: String = ""   // "user" hoặc "admin"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var userName: String = ""

    init() {
        // ✅ Đồng bộ trạng thái nếu Firebase đã có user
        self.user = Auth.auth().currentUser
        if let user = self.user {
            self.isAuthenticated = true
            fetchUserRole(uid: user.uid) { _ in }
        }
    }

    // MARK: - Register
    func register(email: String, password: String, name: String, role: String = "user", completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async { self?.isLoading = false }

            if let error = error {
                completion(false, "❌ \(error.localizedDescription)")
                return
            }

            guard let user = result?.user else {
                completion(false, "Không tạo được user")
                return
            }

            // Gửi email xác minh
            user.sendEmailVerification()

            // Lưu Firestore
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "id": user.uid,
                "email": email,
                "name": name,
                "role": role
            ]) { err in
                if let err = err {
                    completion(false, "Firestore: \(err.localizedDescription)")
                } else {
                    self?.user = user
                    self?.role = role
                    completion(true, "Đăng ký thành công. Kiểm tra email xác minh!")
                }
            }
        }
    }

    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async { self?.isLoading = false }

            if let error = error {
                completion(false, "❌ \(error.localizedDescription)")
                return
            }

            guard let user = result?.user else {
                completion(false, "Không tìm thấy user")
                return
            }

            // Check verify email
            if !user.isEmailVerified {
                completion(false, "⚠️ Email chưa được xác minh.")
                return
            }

            self?.user = user
            self?.isAuthenticated = true
            self?.fetchUserRole(uid: user.uid) { success in
                completion(success, success ? nil : "Không lấy được role")
            }
        }
    }

    // MARK: - Role
    func fetchUserRole(uid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("❌ Firestore: \(error.localizedDescription)")
                self?.role = ""
                completion(false)
                return
            }
            if let data = snapshot?.data(), let role = data["role"] as? String {
                self?.role = role
                completion(true)
            } else {
                self?.role = ""
                completion(false)
            }
        }
    }
    func fetchUserInfo(uid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Firestore: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let data = snapshot?.data() {
                self?.role = data["role"] as? String ?? ""
                self?.userName = data["name"] as? String ?? ""   // ✅ Lấy tên
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    // MARK: - FaceID / TouchID
    func saveLoginInfo(email: String, password: String) {
        UserDefaults.standard.set(email, forKey: "savedEmail")
        UserDefaults.standard.set(password, forKey: "savedPassword")
    }

    func getSavedLoginInfo() -> (String, String)? {
        if let email = UserDefaults.standard.string(forKey: "savedEmail"),
           let password = UserDefaults.standard.string(forKey: "savedPassword") {
            return (email, password)
        }
        return nil
    }

    func loginWithFaceID(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Đăng nhập bằng Face ID / Touch ID"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success, let (email, password) = self.getSavedLoginInfo() {
                        self.login(email: email, password: password, completion: completion)
                    } else {
                        completion(false, authError?.localizedDescription ?? "Xác thực thất bại")
                    }
                }
            }
        } else {
            completion(false, "Thiết bị không hỗ trợ Face ID / Touch ID")
        }
    }

    // MARK: - Logout
    func logout() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.role = ""
            self.isAuthenticated = false
        } catch {
            errorMessage = "❌ Logout lỗi: \(error.localizedDescription)"
        }
    }
}
