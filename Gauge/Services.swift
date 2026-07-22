import Foundation
import CoreLocation
import Observation

// MARK: - Currency Exchange Engine
struct FrankfurterResponse: Codable {
    let rates: [String: Double]
}

struct ExchangeRateService {
    static func fetchRate(from base: String, to target: String) async throws -> Double {
        guard base != target else { return 1.0 }
        
        // Frankfurter is a free, no-key mid-market FX API
        let urlString = "https://api.frankfurter.dev/v1/latest?from=\(base)&to=\(target)"
        guard let url = URL(string: urlString) else { return 1.0 }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        return response.rates[target] ?? 1.0
    }
}

// MARK: - Border Detection Engine
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    var currentCountryCode: String?
    
    override init() {
        super.init()
        manager.delegate = self
        // 100 meters is precise enough for a gas station without burning battery
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestPermissionAndStart() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        manager.stopUpdatingLocation() // Stop instantly to save battery
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let countryCode = placemarks?.first?.isoCountryCode {
                DispatchQueue.main.async {
                    self?.currentCountryCode = countryCode
                }
            }
        }
    }
}
