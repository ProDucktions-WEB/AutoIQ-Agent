import Foundation

/// Low-level HTTP client for Anthropic Messages API.
/// Handles streaming, tool definitions, and request/response serialization.
public final class AnthropicClient {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// Send a non-streaming message request.
    public func sendMessage(_ request: MessagesRequest) async throws -> MessagesResponse {
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try encoder.encode(request)
        applyHeaders(to: &urlRequest)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AnthropicError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return try decoder.decode(MessagesResponse.self, from: data)
    }

    /// Stream a message with chunked responses.
    public func streamMessage(
        _ request: MessagesRequest,
        onDelta: @escaping (StreamEvent) -> Void
    ) async throws {
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        var streamRequest = request
        streamRequest.stream = true
        urlRequest.httpBody = try encoder.encode(streamRequest)
        applyHeaders(to: &urlRequest)

        let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AnthropicError.httpError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        for try await line in bytes.lines {
            guard line.hasPrefix("data: "),
                  line != "data: [DONE]",
                  let data = line.dropFirst(6).data(using: .utf8),
                  let event = try? decoder.decode(StreamEvent.self, from: data) else {
                continue
            }
            onDelta(event)
        }
    }

    private func applyHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
    }
}

// MARK: - Request Models

public struct MessagesRequest: Codable {
    public let model: String
    public let maxTokens: Int
    public let system: String
    public let messages: [APIMessage]
    public let tools: [Tool]?
    public var stream: Bool = false

    enum CodingKeys: String, CodingKey {
        case model, system, messages, tools, stream
        case maxTokens = "max_tokens"
    }

    public init(
        model: String,
        maxTokens: Int,
        system: String,
        messages: [APIMessage],
        tools: [Tool]? = nil,
        stream: Bool = false
    ) {
        self.model = model
        self.maxTokens = maxTokens
        self.system = system
        self.messages = messages
        self.tools = tools
        self.stream = stream
    }
}

public struct APIMessage: Codable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct Tool: Codable {
    public let name: String
    public let description: String
    public let inputSchema: ToolInputSchema

    enum CodingKeys: String, CodingKey {
        case name, description
        case inputSchema = "input_schema"
    }
}

public struct ToolInputSchema: Codable {
    public let type: String
    public let properties: [String: AnyCodable]
    public let required: [String]
}

// MARK: - Response Models

public struct MessagesResponse: Codable {
    public let content: [ContentBlock]
    public let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
    }
}

public struct ContentBlock: Codable {
    public let type: String
    public let text: String?
    public let name: String?
    public let id: String?
    public let input: AnyCodable?

    enum CodingKeys: String, CodingKey {
        case type, text, name, id, input
    }
}

public struct StreamEvent: Codable {
    public let type: String
    public let delta: Delta?

    public struct Delta: Codable {
        public let type: String?
        public let text: String?
    }
}

// MARK: - Errors

public enum AnthropicError: LocalizedError {
    case httpError(Int)
    case decodingError(Error)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "HTTP Error \(code)"
        case .decodingError(let error):
            return "Decoding Error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from API"
        }
    }
}
