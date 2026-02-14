//
//  OpenFoodFactsDTO.swift
//  Bodii
//
//  Open Food Facts API 응답 DTO

import Foundation

/// Open Food Facts 검색 응답 DTO
struct OFFSearchResponseDTO: Codable {
    let count: Int
    let products: [OFFProductDTO]
    let page: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case count
        case products
        case page
        case pageSize = "page_size"
    }
}

/// Open Food Facts 단일 제품 DTO
struct OFFProductDTO: Codable {
    /// 바코드
    let code: String?

    /// 제품명 (기본)
    let productName: String?

    /// 제품명 (한국어)
    let productNameKo: String?

    /// 브랜드명
    let brands: String?

    /// 영양 정보 (100g 기준)
    let nutriments: OFFNutrimentsDTO?

    /// 1회 제공량 텍스트 (예: "120g", "1봉지 (100g)")
    let servingSize: String?

    /// 이미지 URL (소)
    let imageSmallUrl: String?

    /// 카테고리
    let categories: String?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case productNameKo = "product_name_ko"
        case brands
        case nutriments
        case servingSize = "serving_size"
        case imageSmallUrl = "image_small_url"
        case categories
    }
}

/// Open Food Facts 바코드 조회 응답 DTO
struct OFFProductResponseDTO: Codable {
    let status: Int
    let product: OFFProductDTO?
}

/// Open Food Facts 영양 정보 DTO (100g 기준)
struct OFFNutrimentsDTO: Codable {
    /// 에너지 (kcal / 100g)
    let energyKcal100g: Double?

    /// 단백질 (g / 100g)
    let proteins100g: Double?

    /// 탄수화물 (g / 100g)
    let carbohydrates100g: Double?

    /// 지방 (g / 100g)
    let fat100g: Double?

    /// 나트륨 (g / 100g) — mg로 변환 필요
    let sodium100g: Double?

    /// 식이섬유 (g / 100g)
    let fiber100g: Double?

    /// 당류 (g / 100g)
    let sugars100g: Double?

    /// 포화지방 (g / 100g)
    let saturatedFat100g: Double?

    /// 콜레스테롤 (mg / 100g)
    let cholesterol100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case sodium100g = "sodium_100g"
        case fiber100g = "fiber_100g"
        case sugars100g = "sugars_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case cholesterol100g = "cholesterol_100g"
    }
}
