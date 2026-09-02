//
//  OpenFoodFactsProduct.swift
//  MacroPal
//

import Foundation

struct OpenFoodFactsResponse: Decodable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Decodable {
    let productName: String?
    let nutriments: Nutriments?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
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
