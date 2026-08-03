import CoreGraphics

extension CGFloat {
    /// `+1` or `-1` with equal probability. Handy for randomizing initial
    /// launch direction (see `BallNode`) without reaching for a full RNG type.
    static func randomSign() -> CGFloat {
        Bool.random() ? 1 : -1
    }
}
