import SwiftUI
import Supabase
import FirebaseCore

class NewsViewModel: ObservableObject {
    @Published var newsItems: [News] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func fetchNews() {
        isLoading = true
        errorMessage = nil
        
        SupabaseService.shared.fetchNews { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let news):
                    self.newsItems = news
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
