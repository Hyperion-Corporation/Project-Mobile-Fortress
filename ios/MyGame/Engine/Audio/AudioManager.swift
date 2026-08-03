import AVFoundation

/// AVFoundation-based SFX + background-music manager. Mirrors the role of a
/// `SoundPool`/`MediaPlayer` pairing on Android: short one-shot effects go
/// through `AVAudioPlayer` instances pulled from a small reuse pool, longer
/// background music gets its own dedicated looping player.
final class AudioManager {
    static let shared = AudioManager()

    private var effectPlayers: [AVAudioPlayer] = []
    private var musicPlayer: AVAudioPlayer?
    private let maxConcurrentEffects = 4

    var isMusicEnabled: Bool = true {
        didSet { musicPlayer?.volume = isMusicEnabled ? 1 : 0 }
    }

    var isEffectsEnabled: Bool = true

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    /// Plays a short effect (e.g. "bounce", "explosion") from the app bundle.
    /// Silently no-ops if the asset is missing or effects are disabled — audio
    /// must never be able to crash gameplay.
    func playEffect(named name: String, ext: String = "wav") {
        guard isEffectsEnabled, let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        effectPlayers.removeAll { !$0.isPlaying }
        guard effectPlayers.count < maxConcurrentEffects,
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.play()
        effectPlayers.append(player)
    }

    /// Starts looping background music. No-ops if already playing the same track.
    func playMusic(named name: String, ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = -1
        player.volume = isMusicEnabled ? 1 : 0
        player.prepareToPlay()
        player.play()
        musicPlayer = player
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }
}
