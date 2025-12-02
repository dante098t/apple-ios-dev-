
import SwiftUI
import MapKit

// MARK: - Map hiển thị vị trí cửa hàng
struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 10.8032, longitude: 106.7127),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    // Danh sách các vị trí hiển thị trên bản đồ
    let locations = [
        StoreLocation(
            name: "Cửa hàng Apple Store Bình Thạnh",
            address: "2 Trường Sa, Phường 17, Bình Thạnh, TP. Hồ Chí Minh",
            coordinate: CLLocationCoordinate2D(latitude: 10.8032, longitude: 106.7127)
        )
    ]
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: locations) { location in
            MapAnnotation(coordinate: location.coordinate) {
                VStack(spacing: 4) {
                    Button(action: {
                        openInMaps(location)
                    }) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    Text(location.name)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .padding(2)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(4)
                }
            }
        }
        .frame(height: 250)
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Mở Apple Maps khi nhấn vào pin
    private func openInMaps(_ location: StoreLocation) {
        let placemark = MKPlacemark(coordinate: location.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Struct đại diện cho 1 vị trí cửa hàng
struct StoreLocation: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Preview
#Preview {
    MapView()
}
