import Foundation

struct ConversionResponse: Codable {
    let value: String
    let abbreviation: String?
}
struct ErrorResponse: Codable {
    let message: String
}
