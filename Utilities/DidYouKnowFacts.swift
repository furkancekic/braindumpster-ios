import Foundation

struct DidYouKnowFacts {
    private struct FactsData: Codable {
        let facts: [String]
    }

    private static var allFacts: [String] = {
        guard let url = Bundle.main.url(forResource: "did_you_know", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let factsData = try? JSONDecoder().decode(FactsData.self, from: data) else {
            print("⚠️ [DidYouKnowFacts] Could not load facts from JSON")
            return defaultFacts
        }
        return factsData.facts
    }()

    /// Get a random fact
    static func randomFact() -> String {
        return allFacts.randomElement() ?? defaultFacts.randomElement() ?? "Processing your recording..."
    }

    /// Get multiple unique random facts
    static func randomFacts(count: Int) -> [String] {
        let shuffled = allFacts.shuffled()
        return Array(shuffled.prefix(count))
    }

    /// Default facts in case JSON loading fails
    private static let defaultFacts = [
        "The average person spends 31 hours in meetings every month.",
        "Studies show that 71% of meetings are considered unproductive.",
        "Taking notes by hand improves memory retention by 34%.",
        "Your brain continues processing information for hours after a conversation.",
        "The most productive meetings have between 5-8 participants.",
        "AI can now transcribe speech with 95% accuracy.",
        "Your brain uses 20% of your body's energy during intense thinking.",
        "People remember stories 22 times better than facts alone."
    ]
}
