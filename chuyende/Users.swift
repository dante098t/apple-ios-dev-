import Foundation

struct AppUser: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var role: String
}

