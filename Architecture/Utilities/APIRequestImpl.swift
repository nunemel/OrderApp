//
//  APIRequestImpl.swift
//  OrderApp
//
//  Created by Nune Melikyan on 28.10.22.
//

import Foundation

protocol APIRequest {
    func buildURL(
        endPoint: Endpoints,
        queries: [String: String]?
    ) throws -> URL
    func fetch<T: Decodable>(url: URL) async throws -> T
    func fetchData<T: Decodable>(
        for url: URL,
        completion: @escaping (Result<T, Error>) -> Void
    )
}

enum APIRequestError: Error {
    case badURL, badResponse, errorDecoder, invalidURL, itemNotFound
}

final class APIRequestImpl: APIRequest {

    private init() {}

    static let shared = APIRequestImpl()

    func buildURL(
        endPoint: Endpoints,
        queries: [String: String]?
    ) throws -> URL {

        guard let url = URL(string: Constants.baseURL.rawValue) else {
            throw APIRequestError.badURL
        }

        let baseURL = url.appendingPathComponent(endPoint.rawValue)
        var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: true
        )!
        
        if let queries = queries {
            components.queryItems = []
            queries.forEach({ key, value in
                components.queryItems?.append(
                    URLQueryItem(name: key, value: value)
                )
            })
        }

        return components.url!
    }

    // async method
    func fetch<T: Decodable>(url: URL) async throws -> T {

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard (response as? HTTPURLResponse)!.statusCode == 200
        else {
            throw APIRequestError.itemNotFound
        }

        guard
            let object = try? JSONDecoder().decode(
                T.self,
                from: data
            )
        else {
            throw APIRequestError.errorDecoder
        }
        
        return object
    }

    // old method with closure
    func fetchData<T: Decodable>(
        for url: URL,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                completion(.failure(error))
            }

            if let data = data {
                do {
                    let object = try JSONDecoder().decode(
                        T.self,
                        from: data
                    )
                    completion(.success(object))

                }
                catch let errorDecoder {
                    completion(.failure(errorDecoder))
                }
            }
        }.resume()
    }
}
