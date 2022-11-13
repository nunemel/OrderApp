//
//  MenuController.swift
//  OrderApp
//
//  Created by Nune Melikyan on 21.10.22.
//

import Foundation
import UIKit

enum MenuControllerError: Error, LocalizedError {
    case categoryNotFoundError
    case menuItemsNotFound
    case orderRequestFailed
    case imageDataMissing
}

final class MenuController {

    var userActivity = NSUserActivity(
        activityType:
            "com.salvan.OrderApp.order"
    )

    static let orderUpdatedNotification =
        Notification.Name("MenuController.orderUpdated")

    static let shared = MenuController()
    var order = Order() {
        didSet {
            NotificationCenter.default.post(
                name:
                    MenuController.orderUpdatedNotification,
                object: nil
            )
            userActivity.order = order
        }
    }

    typealias MinutesToPrepare = Int

    private var categories: [String] = []
    private var menuItems: [MenuItem] = []

    let categoriesURL: URL = {
        try! APIRequestImpl.shared.buildURL(
            endPoint: Endpoints.categories,
            queries: nil
        )
    }()

    // new
    func fetchCategories() async throws -> [String] {
        let categoriesResponse: CategoriesResponse =
            try await APIRequestImpl.shared.fetch(
                url: self.categoriesURL
            )
        return categoriesResponse.categories
    }

    // old
    func fetchCategories(
        completion: @escaping (
            Result<[String], Error>
        ) -> Void
    ) throws {
        APIRequestImpl.shared.fetchData(for: self.categoriesURL) {
            (result: Result<CategoriesResponse, Error>) in
            switch result {
            case .success(let categoriesResponse):
                self.categories = categoriesResponse.categories
            case .failure(let error):
                print(error)
            }
        }
    }

    func fetchMenuItems(
        forCategory categoryName: String
    ) async throws -> [MenuItem] {
        let menuURL = try APIRequestImpl.shared.buildURL(
            endPoint: Endpoints.menu,
            queries: [Endpoints.category.rawValue: categoryName]
        )
     
        let menuResponse: MenuResponse =
            try await APIRequestImpl.shared.fetch(url: menuURL)

        return menuResponse.items
    }

    func fetchMenuItems(
        forCategory categoryName: String,
        completion: @escaping (Result<MenuResponse, Error>) -> Void
    ) throws {
        let menuURL = try APIRequestImpl.shared.buildURL(
            endPoint: Endpoints.menu,
            queries: [Endpoints.category.rawValue: categoryName]
        )

        APIRequestImpl.shared.fetchData(for: menuURL) {
            (result: Result<MenuResponse, Error>) in
            switch result {
            case .success(let menuResponse):
                print(menuResponse.items)
            case .failure(let error):
                print(error)
            }
        }
    }

    func submitOrder(
        forMenuIDs menuIDs: [Int]
    ) async throws -> MinutesToPrepare {

        let request = try orderRequest(forMenuIDs: menuIDs)

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw MenuControllerError.orderRequestFailed
        }

        let decoder = JSONDecoder()
        let orderResponse = try decoder.decode(
            OrderResponse.self,
            from: data
        )

        return orderResponse.prepTime
    }

    func submitOrder(
        forMenuIDs menuIDs: [Int],
        completion:
            @escaping (Result<MinutesToPrepare, Error>) -> Void
    ) throws {
        let request = try orderRequest(forMenuIDs: menuIDs)

        URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if let data = data {
                do {
                    let orderResponse = try JSONDecoder().decode(
                        OrderResponse.self,
                        from: data
                    )
                    completion(.success(orderResponse.prepTime))
                }
                catch {
                    completion(.failure(error))
                }
            }
            else if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }

    func orderRequest(forMenuIDs menuIDs: [Int]) throws -> URLRequest
    {
        let orderURL = try APIRequestImpl.shared.buildURL(
            endPoint: Endpoints.order,
            queries: nil
        )

        var request = URLRequest(url: orderURL)
        request.httpMethod = Constants.post.rawValue
        request.setValue(
            Constants.applicationJSON.rawValue,
            forHTTPHeaderField: Constants.contentType.rawValue
        )

        let data = [Constants.menuIDs.rawValue: menuIDs]
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(data)
        request.httpBody = jsonData

        return request
    }

    func fetchImage(from url: URL) async throws -> UIImage {

        do {
            // doesn't work with localhost or ip => use ngrok url and  delete the wrong image extension .png
            let urlString = url.absoluteString.replacingOccurrences(of: ".png", with: "")
            let newUrlString = urlString.replacingOccurrences(of: "http://localhost:8080", with: "https://1a6e-37-252-93-15.eu.ngrok.io")

            let newURL = URL(string: newUrlString)!

            let (data, response) = try await URLSession.shared.data(
                from: newURL
            )
            
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                throw MenuControllerError.imageDataMissing
            }
            
            guard let image = UIImage(data: data) else {
                throw MenuControllerError.imageDataMissing
            }
           
            return image
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }

        return UIImage()
    }
    
    func fetchImage(
        url: URL,
        completion: @escaping (UIImage?)
            -> Void
    ) {
        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let data = data,
                let image = UIImage(data: data) {
                completion(image)
            }
            else {
                completion(nil)
            }
        }
        task.resume()
    }

    func updateUserActivity(
        with controller: StateRestorationController
    ) {
        switch controller {
        case .menu(let category):
            userActivity.menuCategory = category
        case .menuItemDetail(let menuItem):
            userActivity.menuItem = menuItem
        case .order, .categories:
            break
        }

        userActivity.controllerIdentifier = controller.identifier
    }
}
