import Foundation

enum FoldDirection: String, Codable, CaseIterable {
    case left
    case right
    case up
    case down

    var title: String {
        switch self {
        case .left: return "Fold Left"
        case .right: return "Fold Right"
        case .up: return "Fold Up"
        case .down: return "Fold Down"
        }
    }

    var symbol: String {
        switch self {
        case .left: return "←"
        case .right: return "→"
        case .up: return "↑"
        case .down: return "↓"
        }
    }
}

struct FoldLevel: Codable {
    let id: Int
    let title: String
    let gridSize: Int
    let glyphs: [[Int?]]
    let solution: [FoldDirection]
    let foldsAllowed: Int
}

struct GameResult: Codable {
    let levelIndex: Int
    let score: Int
    let foldsUsed: Int
    let perfect: Bool
    let passed: Bool
    let date: Date
}

struct HighScoreEntry: Codable {
    let score: Int
    let levelIndex: Int
    let foldsUsed: Int
    let date: Date
}

struct CareerStats: Codable {
    var puzzlesPlayed: Int
    var puzzlesSolved: Int
    var totalFolds: Int
    var bestScore: Int
    var highestLevelCompleted: Int
    var levelBestScores: [Int: Int]

    init(
        puzzlesPlayed: Int = 0,
        puzzlesSolved: Int = 0,
        totalFolds: Int = 0,
        bestScore: Int = 0,
        highestLevelCompleted: Int = -1,
        levelBestScores: [Int: Int] = [:]
    ) {
        self.puzzlesPlayed = puzzlesPlayed
        self.puzzlesSolved = puzzlesSolved
        self.totalFolds = totalFolds
        self.bestScore = bestScore
        self.highestLevelCompleted = highestLevelCompleted
        self.levelBestScores = levelBestScores
    }
}
