import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Model

struct PlaceRecommendation: Equatable {
    let placeName: String
    let categoryKey: String
    let card: CreditCard
    let rate: Double
    let unit: CashbackUnit
}

// MARK: - Manager

class PlaceRecommendationManager: ObservableObject {
    @Published var currentPlace: PlaceRecommendation?

    private let maxPoiDistance: CLLocationDistance = 30
    private var searchTask: Task<Void, Never>?

    @MainActor
    func refresh(at location: CLLocation?, cards: [CreditCard]) async {
        guard let location, !cards.isEmpty else {
            currentPlace = nil
            return
        }
        searchTask?.cancel()
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await self.findRecommendation(at: location, cards: cards)
            guard !Task.isCancelled else { return }
            self.currentPlace = result
        }
        await searchTask?.value
    }

    // MARK: - POI search

    private func findRecommendation(at location: CLLocation, cards: [CreditCard]) async -> PlaceRecommendation? {
        let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: maxPoiDistance)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: relevantCategories)

        guard let response = try? await MKLocalSearch(request: request).start(),
              !response.mapItems.isEmpty else { return nil }

        let closest = response.mapItems.min { a, b in
            let dA = location.distance(from: CLLocation(latitude: a.placemark.coordinate.latitude,
                                                         longitude: a.placemark.coordinate.longitude))
            let dB = location.distance(from: CLLocation(latitude: b.placemark.coordinate.latitude,
                                                         longitude: b.placemark.coordinate.longitude))
            return dA < dB
        }

        guard let item = closest, let name = item.name else { return nil }

        let poiLocation = CLLocation(latitude: item.placemark.coordinate.latitude,
                                     longitude: item.placemark.coordinate.longitude)
        guard location.distance(from: poiLocation) <= maxPoiDistance else { return nil }

        let key = Self.categoryKey(for: item.pointOfInterestCategory)
        guard let (card, rate, unit) = bestCard(for: key, cards: cards) else { return nil }

        return PlaceRecommendation(placeName: name, categoryKey: key, card: card, rate: rate, unit: unit)
    }

    // MARK: - Best card lookup

    private func bestCard(for key: String, cards: [CreditCard]) -> (CreditCard, Double, CashbackUnit)? {
        var result: (CreditCard, Double, CashbackUnit)?
        for targetKey in [key, "other"] {
            for card in cards {
                for cashback in card.cashbackCategories
                    where (cashback.categoryKey ?? "other") == targetKey {
                    if result == nil || cashback.rate > result!.1 {
                        result = (card, cashback.rate, cashback.unit)
                    }
                }
            }
            if result != nil { break }
        }
        return result
    }

    // MARK: - POI → category key

    static func categoryKey(for category: MKPointOfInterestCategory?) -> String {
        guard let category else { return "other" }
        switch category {
        case .restaurant, .cafe, .bakery, .brewery, .winery, .nightlife:
            return "dining"
        case .foodMarket:
            return "groceries"
        case .gasStation:
            return "gas"
        case .airport, .hotel, .publicTransport:
            return "travel"
        default:
            return "other"
        }
    }

    private var relevantCategories: [MKPointOfInterestCategory] {
        [.restaurant, .cafe, .bakery, .brewery, .winery, .nightlife,
         .foodMarket, .gasStation, .airport, .hotel, .publicTransport, .store]
    }
}
