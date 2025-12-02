import SwiftUI
import Supabase
import FirebaseCore 
import Foundation
struct News: Identifiable, Codable {
    let id: Int
    let title: String
    let content: String
    let imageUrl: String?
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case imageUrl = "image_url"
        case date
    }
}


