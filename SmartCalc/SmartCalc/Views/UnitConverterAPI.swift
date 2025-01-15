import Foundation

class UnitConverterAPI {
    static func convert(
        type: String,
        fromUnit: String,
        toUnit: String,
        fromValue: Double,
        completion: @escaping (Result<Double?, Error>) -> Void
    ) {
        let urlString = "https://unit-measurement-conversion.p.rapidapi.com/convert?type=\(type)&fromUnit=\(fromUnit)&toUnit=\(toUnit)&fromValue=\(fromValue)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("unit-measurement-conversion.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.addValue("e3f6cd87b8msha851669dd350d38p1d4d69jsn0657a9a93428", forHTTPHeaderField: "x-rapidapi-key")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Log the raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(jsonString)")
            }
            
            do {
                // Try decoding the success response
                if let successResponse = try? JSONDecoder().decode(ConversionResponse.self, from: data) {
                    if let result = Double(successResponse.value) {
                        completion(.success(result))
                    } else {
                        completion(.success(nil))
                    }
                    return
                }
                
                // Try decoding the error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorResponse.message])))
                    return
                }
                
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unexpected response format"])))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
