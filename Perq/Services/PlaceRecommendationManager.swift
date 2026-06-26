import SwiftUI
import MapKit
import CoreLocation
import Combine
import UIKit

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
    @Published var activeRecommendation: PlaceRecommendation?
    /// Persists after banner dismissal — used by the Cards tab location header.
    @Published var currentPlace: PlaceRecommendation?

    // Must be within this distance of the POI to qualify (roughly inside the building)
    private let maxPoiDistance: CLLocationDistance = 30
    // Must stay near the POI for this many seconds before firing (prevents walk-bys)
    private let requiredDwellSeconds: TimeInterval = 45
    // Don't re-trigger within this radius after a notification was shown
    private let cooldownRadius: CLLocationDistance = 500
    // Ignore location updates faster than walking pace (~1.4 m/s)
    private let maxSpeedMetersPerSecond: CLLocationDistance = 1.8
    // Ignore inaccurate GPS fixes
    private let maxHorizontalAccuracy: CLLocationAccuracy = 25
    // Don't re-search unless user moved this far from the last search point
    private let searchDebounceDistance: CLLocationDistance = 15

    private var lastSearchLocation: CLLocation?
    private var lastRecommendationLocation: CLLocation?
    private var searchTask: Task<Void, Never>?
    private var autoDismissTask: Task<Void, Never>?

    // Dwell tracking — the pending POI the user is lingering near
    private var dwellCandidate: (recommendation: PlaceRecommendation, poiLocation: CLLocation)?
    private var dwellTask: Task<Void, Never>?

    // MARK: - Entry point

    func processLocation(_ location: CLLocation, cards: [CreditCard]) {
        guard !cards.isEmpty else { return }

        // Ignore inaccurate fixes (GPS bounce, tunnels, etc.)
        guard location.horizontalAccuracy <= maxHorizontalAccuracy,
              location.horizontalAccuracy > 0 else { return }

        // Ignore if moving faster than a brisk walk — user is driving or cycling past
        if location.speed > maxSpeedMetersPerSecond { return }

        // Skip if we haven't moved meaningfully since the last search
        if let last = lastSearchLocation, location.distance(from: last) < searchDebounceDistance { return }
        lastSearchLocation = location

        // Still within cooldown zone of the last shown recommendation — don't search again
        if let lastRec = lastRecommendationLocation, location.distance(from: lastRec) < cooldownRadius { return }

        searchTask?.cancel()
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            guard let (rec, poiLoc) = await self.findRecommendation(at: location, cards: cards) else {
                // User is not near any relevant POI — cancel any pending dwell
                self.cancelDwell()
                return
            }
            guard !Task.isCancelled else { return }

            // If this is the same POI as the current dwell candidate, keep waiting
            if let existing = self.dwellCandidate,
               existing.recommendation == rec { return }

            // New POI — reset dwell timer
            self.startDwell(recommendation: rec, poiLocation: poiLoc, userLocation: location, cards: cards)
        }
    }

    // MARK: - Dismiss

    func dismiss() {
        autoDismissTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            activeRecommendation = nil
        }
    }

    // MARK: - Dwell timer

    @MainActor
    private func startDwell(recommendation: PlaceRecommendation, poiLocation: CLLocation,
                             userLocation: CLLocation, cards: [CreditCard]) {
        dwellTask?.cancel()
        dwellCandidate = (recommendation, poiLocation)

        dwellTask = Task { @MainActor [weak self] in
            // Wait for the required dwell time
            try? await Task.sleep(nanoseconds: UInt64(self?.requiredDwellSeconds ?? 45) * 1_000_000_000)
            guard !Task.isCancelled, let self else { return }
            // Confirm the candidate is still set (user hasn't left)
            guard let candidate = self.dwellCandidate,
                  candidate.recommendation == recommendation else { return }
            self.dwellCandidate = nil
            self.show(recommendation, triggeredAt: userLocation)
        }
    }

    @MainActor
    private func cancelDwell() {
        dwellTask?.cancel()
        dwellCandidate = nil
    }

    // MARK: - Show

    @MainActor
    private func show(_ recommendation: PlaceRecommendation, triggeredAt location: CLLocation) {
        lastRecommendationLocation = location

        let isForegrounded = UIApplication.shared.applicationState == .active
        currentPlace = recommendation

        if isForegrounded {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                activeRecommendation = recommendation
            }
            autoDismissTask?.cancel()
            autoDismissTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                guard !Task.isCancelled else { return }
                self?.dismiss()
            }
        } else {
            NotificationManager.shared.sendRecommendation(recommendation)
        }
    }

    // MARK: - POI search

    private func findRecommendation(at location: CLLocation,
                                    cards: [CreditCard]) async -> (PlaceRecommendation, CLLocation)? {
        let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: maxPoiDistance)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: relevantCategories)

        guard let response = try? await MKLocalSearch(request: request).start(),
              !response.mapItems.isEmpty else { return nil }

        // Pick the closest POI
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
        let distance = location.distance(from: poiLocation)

        // Must be within the tight radius
        guard distance <= maxPoiDistance else { return nil }

        let key = Self.categoryKey(for: item.pointOfInterestCategory)
        guard let (card, rate, unit) = bestCard(for: key, cards: cards) else { return nil }

        let rec = PlaceRecommendation(placeName: name, categoryKey: key, card: card, rate: rate, unit: unit)
        return (rec, poiLocation)
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

    // MARK: - POI → category_key

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
