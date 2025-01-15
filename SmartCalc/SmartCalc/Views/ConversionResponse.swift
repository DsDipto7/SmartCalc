import Foundation

// Response model for successful conversion
struct ConversionResponse: Codable {
    let value: String
    let abbreviation: String?
}

// Response model for errors
struct ErrorResponse: Codable {
    let message: String
}
