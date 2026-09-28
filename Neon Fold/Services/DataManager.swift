import Foundation

final class DataManager {
    static let shared = DataManager()

    private let highScoresKey = "neon_fold_high_scores"
    private let careerStatsKey = "neon_fold_career_stats"
    private let maxEntries = 10

    private init() {}

    func loadHighScores() -> [HighScoreEntry] {
        guard let data = UserDefaults.standard.data(forKey: highScoresKey),
              let scores = try? JSONDecoder().decode([HighScoreEntry].self, from: data) else {
            return []
        }
        return scores.sorted { $0.score > $1.score }
    }

    @discardableResult
    func submitScore(_ result: GameResult) -> Bool {
        var scores = loadHighScores()
        let entry = HighScoreEntry(
            score: result.score,
            levelIndex: result.levelIndex,
            foldsUsed: result.foldsUsed,
            date: result.date
        )
        let bestBefore = scores.first?.score ?? 0
        scores.append(entry)
        scores.sort { $0.score > $1.score }
        if scores.count > maxEntries {
            scores = Array(scores.prefix(maxEntries))
        }
        if let encoded = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(encoded, forKey: highScoresKey)
        }
        recordCareer(with: result)
        return result.score > bestBefore
    }

    func bestScore() -> Int {
        loadHighScores().first?.score ?? 0
    }

    func resetHighScores() {
        UserDefaults.standard.removeObject(forKey: highScoresKey)
    }

    func loadCareerStats() -> CareerStats {
        guard let data = UserDefaults.standard.data(forKey: careerStatsKey),
              let stats = try? JSONDecoder().decode(CareerStats.self, from: data) else {
            return CareerStats()
        }
        return stats
    }

    private func saveCareerStats(_ stats: CareerStats) {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: careerStatsKey)
        }
    }

    private func recordCareer(with result: GameResult) {
        var stats = loadCareerStats()
        stats.puzzlesPlayed += 1
        stats.totalFolds += result.foldsUsed
        stats.bestScore = max(stats.bestScore, result.score)

        let previousLevelBest = stats.levelBestScores[result.levelIndex] ?? 0
        if result.score > previousLevelBest {
            stats.levelBestScores[result.levelIndex] = result.score
        }
        if result.passed {
            stats.puzzlesSolved += 1
            stats.highestLevelCompleted = max(stats.highestLevelCompleted, result.levelIndex)
        }
        saveCareerStats(stats)
    }

    func resetCareer() {
        UserDefaults.standard.removeObject(forKey: careerStatsKey)
    }
}
