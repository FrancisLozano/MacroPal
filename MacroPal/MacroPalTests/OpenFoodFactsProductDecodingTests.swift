//
//  OpenFoodFactsProductDecodingTests.swift
//  MacroPalTests
//

import Testing
import Foundation
@testable import MacroPal

struct OpenFoodFactsProductDecodingTests {
    @Test func decodesFoundProductWithHyphenatedNutrimentKeys() throws {
        let json = """
        {
            "status": 1,
            "product": {
                "product_name": "Peanut Butter",
                "nutriments": {
                    "energy-kcal_100g": 588,
                    "proteins_100g": 25,
                    "carbohydrates_100g": 20,
                    "fat_100g": 50
                }
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: json)
        #expect(response.status == 1)
        #expect(response.product?.productName == "Peanut Butter")
        #expect(response.product?.nutriments?.energyKcalPer100g == 588)
        #expect(response.product?.nutriments?.proteinsPer100g == 25)
        #expect(response.product?.nutriments?.carbohydratesPer100g == 20)
        #expect(response.product?.nutriments?.fatPer100g == 50)
    }

    @Test func decodesNotFoundResponse() throws {
        let json = """
        { "status": 0, "product": null }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: json)
        #expect(response.status == 0)
        #expect(response.product == nil)
    }

    @Test func decodesMissingNutrimentFieldsAsNil() throws {
        let json = """
        {
            "status": 1,
            "product": {
                "product_name": "Mystery Snack",
                "nutriments": {
                    "energy-kcal_100g": 250
                }
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: json)
        #expect(response.product?.nutriments?.energyKcalPer100g == 250)
        #expect(response.product?.nutriments?.proteinsPer100g == nil)
        #expect(response.product?.nutriments?.carbohydratesPer100g == nil)
        #expect(response.product?.nutriments?.fatPer100g == nil)
    }

    @Test func decodesResponseWithNoProductNameGracefully() throws {
        let json = """
        {
            "status": 1,
            "product": {
                "nutriments": { "energy-kcal_100g": 100 }
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: json)
        #expect(response.product?.productName == nil)
    }
}
