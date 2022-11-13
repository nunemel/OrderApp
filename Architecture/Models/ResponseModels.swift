//
//  ResponseModels.swift
//  OrderApp
//
//  Created by Nune Melikyan on 21.10.22.
//

import Foundation

struct MenuResponse: Decodable {
    let items: [MenuItem]
}

struct CategoriesResponse: Decodable {
    let categories: [String]
}

struct OrderResponse: Decodable {
    let prepTime: Int

    enum CodingKeys: String, CodingKey {
        case prepTime = "preparation_time"
    }
}

struct Order: Encodable, Decodable {
    var menuItems: [MenuItem]

    init(
        menuItems: [MenuItem] = []
    ) {
        self.menuItems = menuItems
    }
}
