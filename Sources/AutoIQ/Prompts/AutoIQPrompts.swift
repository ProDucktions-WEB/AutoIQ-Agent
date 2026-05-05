import Foundation

/// Single source of truth for all Auto IQ prompts and tool definitions.
/// Edit the system prompt here to change agent behavior globally.
public enum AutoIQPrompts {

    /// Loads the system prompt from the bundled text file.
    public static var systemPrompt: String = {
        if let url = Bundle.module.url(forResource: "SystemPrompt", withExtension: "txt"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return defaultSystemPrompt
    }()

    /// Fallback system prompt if file is not found.
    private static let defaultSystemPrompt = """
    You are Auto IQ, an intelligent automotive advisor for the Colombian market.
    You assist users in finding and evaluating vehicles while protecting their financial interests.
    """
}
