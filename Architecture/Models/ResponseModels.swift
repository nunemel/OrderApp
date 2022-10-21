//
//  ResponseModels.swift
//  OrderApp
//
//  Created by Nune Melikyan on 21.10.22.
//

import Foundation

struct MenuResponse: Codable {
    let items: [MenuItem]
}

struct CategoriesResponse: Codable {
    let categories: [String]
}

struct OrderResponse: Codable {
    let prepTime: Int

    enum CodingKeys: String, CodingKey {
        case prepTime = "preparation_time"
    }
}

struct Order: Codable {
    var menuItems: [MenuItem]

    init(
        menuItems: [MenuItem] = []
    ) {
        self.menuItems = menuItems
    }
}
