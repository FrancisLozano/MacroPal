//
//  OpenFoodFactsClient.swift
//  MacroPal
//

import Foundation

enum OpenFoodFactsError: Error {
    case invalidURL
    case networkFailure(Error)
    case httpError(Int)
    case decodingFailure(Error)
}

/// A plain, keyless GET against the Open Food Facts public API — no API key or signup
/// required, unlike a keyed nutrition API (Nutritionix, Edamam, USDA).
@MainActor
struct OpenFoodFactsClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Returns `nil` for a genuine "not found" (Open Food Facts `status == 0`), which is
    /// not an error — the barcode is fine, it's just not in the database. Throws for
    /// actual request/decoding failures.
    func lookupProduct(barcode: String) async throws -> OpenFoodFactsProduct? {
        guard let encodedBarcode = barcode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(encodedBarcode).json?fields=product_name,nutriments") else {
            throw OpenFoodFactsError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw OpenFoodFactsError.networkFailure(error)
        }

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw OpenFoodFactsError.httpError(httpResponse.statusCode)
        }

        let decoded: OpenFoodFactsResponse
        do {
            decoded = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        } catch {
            throw OpenFoodFactsError.decodingFailure(error)
        }

        return decoded.status == 1 ? decoded.product : nil
    }
}
