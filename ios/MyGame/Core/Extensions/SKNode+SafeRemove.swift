import SpriteKit

extension SKNode {
    /// `removeFromParent()` is a no-op if already detached, but calling it
    /// redundantly across overlapping cleanup paths (e.g. a contact handler
    /// and an off-screen check firing the same frame) is a common source of
    /// double-scoring bugs if callers gate other logic on "did I just remove
    /// this". This makes that intent explicit and returns whether it actually
    /// did anything.
    @discardableResult
    func safeRemoveFromParent() -> Bool {
        guard parent != nil else { return false }
        removeFromParent()
        return true
    }
}
