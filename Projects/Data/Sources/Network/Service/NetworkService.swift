//
//  NetworkService.swift
//  Data
//
//  Created by 이윤수 on 7/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Core

final class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Properties
    
    private let session: URLSessionProtocol
    
    // MARK: - LifeCycle
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    // MARK: - Methods
    func request<T>(
        endPoint: Endpoint,
        responseType: T.Type
    ) async throws(NetworkError)
    -> T where T : Decodable {
        let url = try self.makeURL(urlString: endPoint.fullURL, enableLog: endPoint.enableLog)
        var request = URLRequest(url: url)
        request.httpMethod = endPoint.method.rawValue
        request.timeoutInterval = endPoint.timeout
        
        let data = try await self.performRequest(urlRequest: request, enableLog: endPoint.enableLog)
        
        let decoded: T
        do {
            decoded = try JSONDecoder().decode(responseType, from: data)
        } catch {
            AppLogger.network.log(.error, "❌ 디코딩 오류: \(String(describing: responseType)), \(error.localizedDescription)", enableLog: endPoint.enableLog)
            throw .decodingError
        }
        
        return decoded
    }
}

private extension NetworkService {
    func makeURL(urlString: String,  enableLog: Bool) throws(NetworkError) -> URL {
        guard let url = URL(string: urlString) else {
            AppLogger.network.log(.error, "❌ URL 변환 에러: \(urlString)", enableLog: enableLog)
            throw .invalidURL
        }
        return url
    }
    
    func performRequest(urlRequest: URLRequest, enableLog: Bool) async throws(NetworkError) -> Data {
        let urlString = urlRequest.url?.absoluteString ?? ""
        AppLogger.network.log(.info, "네트워크 통신 요청: \(urlString)\n메소드: \(urlRequest.httpMethod ?? "")", enableLog: enableLog)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await self.session.data(request: urlRequest)
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    AppLogger.network.log(.error, "❌ 네트워크 타임아웃", enableLog: enableLog)
                    throw .timeout
                case .cancelled:
                    AppLogger.network.log(.debug, "네트워크 요청 취소됨", enableLog: enableLog)
                    throw .cancelled
                default:
                    AppLogger.network.log(.error, "❌ 네트워크 에러: \(error.localizedDescription)", enableLog: enableLog)
                    throw .networkError
                }
            } else {
                AppLogger.network.log(.error, "❌ 네트워크 에러: \(error.localizedDescription)", enableLog: enableLog)
                throw .networkError
            }
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.network.log(.error, "❌ HTTPURLResponse 변환 실패", enableLog: enableLog)
            throw .unknown
        }
        
        AppLogger.network.log(.info, "통신 Status: \(httpResponse.statusCode) -  \(urlString)", enableLog: enableLog)
        
        if let responseString = String(data: data, encoding: .utf8) {
            AppLogger.network.log(.debug, "데이터 원문: \(responseString.prefix(200))", enableLog: enableLog)
        }
        
        guard (200 ..< 400) ~= httpResponse.statusCode else {
            if (400 ... 499) ~= httpResponse.statusCode {
                AppLogger.network.log(.error, "❌ 클라이언트 오류", enableLog: enableLog)
                throw .clientError
            } else if (500 ... 599) ~= httpResponse.statusCode {
                AppLogger.network.log(.error, "❌ 서버 오류", enableLog: enableLog)
                throw .serverError
            } else {
                AppLogger.network.log(.error, "❌ 알 수 없는 오류", enableLog: enableLog)
                throw .unknown
            }
        }
        return data
    }
}
