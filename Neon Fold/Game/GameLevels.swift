import Foundation

enum GameLevels {
    static let all: [FoldLevel] = [
        FoldLevel(
            id: 1,
            title: "First Crease",
            gridSize: 2,
            glyphs: [
                [1, 1],
                [nil, nil]
            ],
            solution: [.left],
            foldsAllowed: 1
        ),
        FoldLevel(
            id: 2,
            title: "Mirror Cyan",
            gridSize: 2,
            glyphs: [
                [2, nil],
                [2, nil]
            ],
            solution: [.up],
            foldsAllowed: 1
        ),
        FoldLevel(
            id: 3,
            title: "Cross Match",
            gridSize: 2,
            glyphs: [
                [3, nil],
                [nil, 3]
            ],
            solution: [.right],
            foldsAllowed: 1
        ),
        FoldLevel(
            id: 4,
            title: "Double Fold",
            gridSize: 2,
            glyphs: [
                [1, 2],
                [2, 1]
            ],
            solution: [.left, .up],
            foldsAllowed: 2
        ),
        FoldLevel(
            id: 5,
            title: "Triad Sheet",
            gridSize: 3,
            glyphs: [
                [4, nil, 4],
                [nil, 1, nil],
                [nil, nil, nil]
            ],
            solution: [.left],
            foldsAllowed: 1
        ),
        FoldLevel(
            id: 6,
            title: "Neon Cascade",
            gridSize: 3,
            glyphs: [
                [5, nil, nil],
                [5, nil, nil],
                [5, nil, nil]
            ],
            solution: [.up, .up],
            foldsAllowed: 2
        ),
        FoldLevel(
            id: 7,
            title: "Glyph Pairing",
            gridSize: 3,
            glyphs: [
                [2, 3, nil],
                [nil, nil, nil],
                [2, 3, nil]
            ],
            solution: [.up],
            foldsAllowed: 1
        ),
        FoldLevel(
            id: 8,
            title: "Layer Stack",
            gridSize: 3,
            glyphs: [
                [6, nil, 1],
                [nil, 6, nil],
                [1, nil, nil]
            ],
            solution: [.right, .down],
            foldsAllowed: 2
        ),
        FoldLevel(
            id: 9,
            title: "Quad Pulse",
            gridSize: 4,
            glyphs: [
                [1, nil, nil, 1],
                [nil, 2, 2, nil],
                [nil, nil, nil, nil],
                [nil, nil, nil, nil]
            ],
            solution: [.left, .up],
            foldsAllowed: 2
        ),
        FoldLevel(
            id: 10,
            title: "Deep Crease",
            gridSize: 4,
            glyphs: [
                [3, nil, 3, nil],
                [4, nil, 4, nil],
                [nil, nil, nil, nil],
                [nil, nil, nil, nil]
            ],
            solution: [.left],
            foldsAllowed: 1
        ),
        FoldLevel(
            id: 11,
            title: "Prism Path",
            gridSize: 4,
            glyphs: [
                [5, nil, nil, nil],
                [nil, 5, nil, nil],
                [nil, nil, 5, nil],
                [nil, nil, nil, 5]
            ],
            solution: [.left, .up, .left],
            foldsAllowed: 3
        ),
        FoldLevel(
            id: 12,
            title: "Final Glow",
            gridSize: 4,
            glyphs: [
                [1, 2, nil, 6],
                [nil, nil, 2, nil],
                [1, nil, nil, 6],
                [nil, 3, 3, nil]
            ],
            solution: [.right, .up, .left],
            foldsAllowed: 3
        )
    ]

    static func level(at index: Int) -> FoldLevel? {
        guard index >= 0, index < all.count else { return nil }
        return all[index]
    }

    static func isUnlocked(index: Int, highestCompleted: Int) -> Bool {
        if index <= 0 { return true }
        return index <= highestCompleted + 1
    }
}
