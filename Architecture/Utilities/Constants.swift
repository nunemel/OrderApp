//
//  Constants.swift
//  OrderApp
//
//  Created by Nune Melikyan on 28.10.22.
//

import Foundation

enum Constants: String {
    case baseURL = "http://127.0.0.1:8080"
    case post = "POST"
    case get = "GET"
    case contentType = "Content-Type"
    case applicationJSON = "application/json"
    case menuIDs = "menuIds"
}

enum Endpoints: String {
    case categories = "categories"
    case category = "category"
    case images = "images"
    case menu = "menu"
    case order = "order"
}
