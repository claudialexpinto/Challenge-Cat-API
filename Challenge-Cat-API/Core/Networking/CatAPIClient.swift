//
//  CatAPIClient.swift
//  Challenge-Cat-API
//
//  Created by Claudia Pinto - Pessoal on 02/09/2025.
//
import ComposableArchitecture
import Foundation

enum CatAPIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida."
        case .requestFailed(let err):
            return "Request failed: \(err.localizedDescription)"
        case .decodingFailed(let err):
            return "Decoding failed: \(err.localizedDescription)"
        }
    }
}

protocol CatAPIClientProtocol {
    func fetchCats(page: Int, limit: Int) async throws -> [Cat]
}

struct CatAPIClient: CatAPIClientProtocol {
    private let baseURL = "https://api.thecatapi.com/v1/images/search"
    
    static var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let key = dict["THECATAPI_KEY"] as? String else {
            fatalError("API key não encontrada")
        }
        return key
    }
    
    func fetchCats(page: Int, limit: Int) async throws -> [Cat] {
        guard var components = URLComponents(string: baseURL) else {
            throw CatAPIError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "order", value: "ASC"),
            URLQueryItem(name: "has_breeds", value: "1")
        ]
        
        guard let url = components.url else {
            throw CatAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(CatAPIClient.apiKey, forHTTPHeaderField: "x-api-key")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            return try decoder.decode([Cat].self, from: data)
        } catch let error as DecodingError {
            throw CatAPIError.decodingFailed(error)
        } catch {
            throw CatAPIError.requestFailed(error)
        }
    }
}
