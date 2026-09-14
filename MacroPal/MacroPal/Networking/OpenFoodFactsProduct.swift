//
//  OpenFoodFactsProduct.swift
//  MacroPal
//

import Foundation

struct OpenFoodFactsResponse: Decodable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

/// Response shape for the search-a-licious text-search endpoint
/// (search.openfoodfacts.org/search), distinct from the single-barcode-lookup endpoint's
/// `OpenFoodFactsResponse`.
struct OpenFoodFactsHitsResponse: Decodable {
    let hits: [OpenFoodFactsProduct]
}

struct OpenFoodFactsProduct: Decodable {
    let productName: String?
    let nutriments: Nutriments?
    /// Only present on search results (not the single-product lookup, which is already
    /// keyed by barcode) — lets a search result be matched against an existing local item.
    let code: String?
    private let brands: FlexibleBrand?
    /// A human string like "1 medium apple (182 g)" — only populated by the single-barcode
    /// lookup endpoint; the text-search endpoint doesn't index/return this field.
    let servingSize: String?
    let servingQuantity: Double?

    /// First listed brand (Open Food Facts allows several, comma/array-separated), if any.
    var brandName: String? { brands?.first }

    /// `servingSize` with its leading "1 " and trailing "(…)" gram/volume parenthetical
    /// stripped, e.g. "1 medium apple (182 g)" -> "medium apple" — a short label fit for a
    /// unit picker button rather than a full sentence. `nil` when there's nothing usable.
    var servingUnitLabel: String? {
        guard var text = servingSize else { return nil }
        if let range = text.range(of: #"\s*\([^)]*\)\s*$"#, options: .regularExpression) {
            text.removeSubrange(range)
        }
        text = text.trimmingCharacters(in: .whitespaces)
        if text.lowercased().hasPrefix("1 ") {
            text = String(text.dropFirst(2))
        }
        return text.isEmpty ? nil : text
    }

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
        case code
        case brands
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
    }

    /// Open Food Facts encodes a product's brand list differently depending on the endpoint
    /// — a single comma-separated string on the classic barcode-lookup API, an array of
    /// strings on the newer search-a-licious API. Decodes either shape into a plain list.
    private struct FlexibleBrand: Decodable {
        let values: [String]

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let array = try? container.decode([String].self) {
                values = array.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else if let string = try? container.decode(String.self) {
                values = string.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else {
                values = []
            }
        }

        var first: String? { values.first }
    }

    /// Field names use hyphens in the raw JSON (e.g. "energy-kcal_100g"), which aren't
    /// valid Swift identifiers, so every key needs an explicit mapping.
    struct Nutriments: Decodable {
        let energyKcalPer100g: Double?
        let proteinsPer100g: Double?
        let carbohydratesPer100g: Double?
        let fatPer100g: Double?

        enum CodingKeys: String, CodingKey {
            case energyKcalPer100g = "energy-kcal_100g"
            case proteinsPer100g = "proteins_100g"
            case carbohydratesPer100g = "carbohydrates_100g"
            case fatPer100g = "fat_100g"
        }
    }
}
