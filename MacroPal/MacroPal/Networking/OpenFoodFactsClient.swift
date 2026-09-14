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
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(encodedBarcode).json?fields=product_name,nutriments,brands,serving_size,serving_quantity") else {
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

    /// Free-text search against Open Food Facts' search-a-licious API (search.openfoodfacts.org)
    /// rather than the legacy `cgi/search.pl` endpoint — the legacy endpoint has no real
    /// relevance ranking (it's just token matches in database order), so "orange" surfaced
    /// obscure multi-word products like "Biscuit Soja Orange" ahead of the plain fruit. This
    /// endpoint runs an actual relevance-scored full-text search (product name matches are
    /// boosted), so an exact/near-exact name match like "Orange" ranks at or near the top.
    /// It also silently dropped requests under `sort_by`, an attempt to fix the legacy
    /// endpoint's ranking by popularity, with intermittent 503s — this one is both more
    /// relevant and more reliable. Results with no product name are dropped client-side —
    /// the public database has plenty of barcode-only stub entries that would otherwise show
    /// up as blank rows.
    func searchProducts(matching query: String, pageSize: Int = 25) async throws -> [OpenFoodFactsProduct] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://search.openfoodfacts.org/search?q=\(encodedQuery)&page_size=\(pageSize)&fields=product_name,nutriments,code,brands") else {
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

        let decoded: OpenFoodFactsHitsResponse
        do {
            decoded = try JSONDecoder().decode(OpenFoodFactsHitsResponse.self, from: data)
        } catch {
            throw OpenFoodFactsError.decodingFailure(error)
        }

        return decoded.hits.filter { ($0.productName?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) == false }
    }
}
