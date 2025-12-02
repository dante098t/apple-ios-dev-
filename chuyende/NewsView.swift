import SwiftUI
import PhotosUI
import Supabase
import FirebaseCore
import Foundation

struct NewsView: View {
    @StateObject private var newsViewModel = NewsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if newsViewModel.isLoading {
                    ProgressView("Đang tải tin tức...")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = newsViewModel.errorMessage {
                    VStack {
                        Text("Lỗi: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.subheadline)
                        Button(action: {
                            newsViewModel.fetchNews()
                        }) {
                            Text("Thử lại")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                            newsViewModel.fetchNews()
                        }
                        LazyVStack(spacing: 20) {
                            ForEach(newsViewModel.newsItems) { news in
                                NewsCard(news: news)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .coordinateSpace(name: "pullToRefresh")
                }
            }
            .navigationTitle("Tin tức")
            .onAppear {
                if newsViewModel.newsItems.isEmpty {
                    newsViewModel.fetchNews()
                }
            }
        }
    }
}

// Thành phần NewsCard với thiết kế banner
struct NewsCard: View {
    let news: News
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Hình ảnh nền
            if let urlStr = news.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    case .empty:
                        Color.gray.opacity(0.2)
                            .frame(height: 200)
                            .overlay(ProgressView())
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    case .failure:
                        Color.gray.opacity(0.2)
                            .frame(height: 200)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Color.gray.opacity(0.2)
                    .frame(height: 200)
                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Lớp phủ gradient để văn bản dễ đọc
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.6), .black.opacity(0.1)]),
                startPoint: .bottom,
                endPoint: .top
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Nội dung văn bản
            VStack(alignment: .leading, spacing: 8) {
                Text(news.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(news.content)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                Text(news.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
        .padding(.vertical, 5)
        .scaleEffect(1.0) // Hỗ trợ hiệu ứng nhấn
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

// Thành phần PullToRefresh
struct PullToRefresh: View {
    var coordinateSpaceName: String
    var onRefresh: () -> Void
    
    @State private var needRefresh: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .named(coordinateSpaceName)).origin.y > 50 {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if needRefresh {
                Spacer()
                    .onAppear {
                        needRefresh = false
                        onRefresh()
                    }
            }
        }
        .frame(height: 0)
    }
}
