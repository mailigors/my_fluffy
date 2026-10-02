import AVFoundation
import Foundation

enum BundleFile {
    static func url(name: String, extension ext: String, subdirectory: String) -> URL? {
        guard let root = Bundle(for: PetStore.self).resourceURL else { return nil }
        let file = "\(name).\(ext)"
        let candidates = [
            root.appendingPathComponent(subdirectory, isDirectory: true).appendingPathComponent(file),
            root.appendingPathComponent(subdirectory.components(separatedBy: "/").last ?? subdirectory, isDirectory: true).appendingPathComponent(file),
            root.appendingPathComponent(file)
        ]
        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }
}

protocol SoundPlaying: AnyObject {
    var effectsEnabled: Bool { get set }
    func prepareSession()
    func playMeow()
    func playHappyMeow()
    func playEating()
    func startPurr()
    func stopPurr()
    func startSnore()
    func stopSnore()
    func playFaucetOpen()
    func startWater()
    func stopWater()
    func startSizzle()
    func stopSizzle()
    func startMusic()
    func stopMusic()
    func setMusicQuiet(_ quiet: Bool)
}

final class BundleSoundPlayer: SoundPlaying {
    var effectsEnabled = true

    private let volume: Float = 0.45
    private let sleepVolume: Float = 0.18
    private let waterVolume: Float = 0.12
    private let sizzleVolume: Float = 0.16
    private let musicVolume: Float = 0.04
    private var meowPlayer: AVAudioPlayer?
    private var happyPlayer: AVAudioPlayer?
    private var eatingPlayer: AVAudioPlayer?
    private var purrPlayer: AVAudioPlayer?
    private var snorePlayer: AVAudioPlayer?
    private var faucetPlayer: AVAudioPlayer?
    private var waterPlayer: AVAudioPlayer?
    private var sizzlePlayer: AVAudioPlayer?
    private var musicPlayer: AVAudioPlayer?
    private var musicQuiet = false
    private var musicToken = 0
    private var purrToken = 0
    private var snoreToken = 0

    func prepareSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default)
        try? session.setActive(true)
    }

    func playMeow() {
        playOnce(&meowPlayer, named: "meow_01")
    }

    func playHappyMeow() {
        playOnce(&happyPlayer, named: "mrr_meow")
    }

    func playEating() {
        playOnce(&eatingPlayer, named: "mrr_meow", playbackVolume: 0.25)
    }

    func startPurr() {
        purrToken += 1
        startLoop(&purrPlayer, named: "purr_loop", other: snorePlayer)
    }

    func stopPurr() {
        purrToken += 1
        let token = purrToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.purrToken == token else { return }
            self.fadeOut(self.purrPlayer, token: token) { [weak self] current in
                self?.purrToken == current
            }
        }
    }

    func startSnore() {
        snoreToken += 1
        startLoop(&snorePlayer, named: "purr_loop", other: purrPlayer, playbackVolume: sleepVolume)
    }

    func stopSnore() {
        snoreToken += 1
        fadeOut(snorePlayer, token: snoreToken) { [weak self] token in
            self?.snoreToken == token
        }
    }

    func playFaucetOpen() {
        playOnce(&faucetPlayer, named: "faucet_open", playbackVolume: 0.15)
    }

    func startWater() {
        guard effectsEnabled else { return }
        if waterPlayer == nil { waterPlayer = makePlayer(named: "water_loop") }
        guard let waterPlayer, !waterPlayer.isPlaying else { return }
        waterPlayer.numberOfLoops = -1
        waterPlayer.volume = waterVolume
        waterPlayer.currentTime = 0
        waterPlayer.play()
    }

    func stopWater() {
        waterPlayer?.stop()
        waterPlayer?.currentTime = 0
    }

    func startSizzle() {
        guard effectsEnabled else { return }
        if sizzlePlayer == nil { sizzlePlayer = makePlayer(named: "cooking_sizzle") }
        guard let sizzlePlayer, !sizzlePlayer.isPlaying else { return }
        sizzlePlayer.numberOfLoops = -1
        sizzlePlayer.volume = sizzleVolume
        sizzlePlayer.currentTime = 0
        sizzlePlayer.play()
    }

    func stopSizzle() {
        sizzlePlayer?.stop()
        sizzlePlayer?.currentTime = 0
    }

    func startMusic() {
        musicToken += 1
        if musicPlayer == nil { musicPlayer = makePlayer(named: "music_day") }
        guard let musicPlayer else { return }
        let target = musicQuiet ? musicVolume * 0.45 : musicVolume
        if musicPlayer.isPlaying {
            musicPlayer.setVolume(target, fadeDuration: 0.5)
            return
        }
        musicPlayer.numberOfLoops = -1
        musicPlayer.currentTime = 0
        musicPlayer.volume = 0
        musicPlayer.play()
        musicPlayer.setVolume(target, fadeDuration: 0.8)
    }

    func stopMusic() {
        musicToken += 1
        let token = musicToken
        guard let musicPlayer, musicPlayer.isPlaying else { return }
        musicPlayer.setVolume(0, fadeDuration: 0.25)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self, self.musicToken == token else { return }
            musicPlayer.stop()
            musicPlayer.currentTime = 0
        }
    }

    func setMusicQuiet(_ quiet: Bool) {
        musicQuiet = quiet
        musicPlayer?.setVolume(quiet ? musicVolume * 0.45 : musicVolume, fadeDuration: 1.0)
    }

    private func playOnce(_ player: inout AVAudioPlayer?, named name: String, playbackVolume: Float? = nil) {
        guard effectsEnabled else { return }
        if player == nil {
            player = makePlayer(named: name)
        }
        guard let player else { return }
        player.numberOfLoops = 0
        player.stop()
        player.currentTime = 0
        player.volume = playbackVolume ?? volume
        player.play()
    }

    private func startLoop(
        _ player: inout AVAudioPlayer?,
        named name: String,
        other: AVAudioPlayer?,
        playbackVolume: Float? = nil
    ) {
        guard effectsEnabled else { return }
        fadeOutImmediately(other)
        if player == nil {
            player = makePlayer(named: name)
        }
        guard let player else { return }
        player.numberOfLoops = -1
        player.volume = playbackVolume ?? volume
        if player.isPlaying {
            return
        }
        player.currentTime = 0
        player.play()
    }

    private func fadeOut(_ player: AVAudioPlayer?, token: Int, matches: @escaping (Int) -> Bool) {
        guard let player, player.isPlaying else { return }
        player.setVolume(0, fadeDuration: 0.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard matches(token) else { return }
            player.stop()
            player.currentTime = 0
            player.volume = self.volume
        }
    }

    private func fadeOutImmediately(_ player: AVAudioPlayer?) {
        guard let player else { return }
        player.stop()
        player.currentTime = 0
        player.volume = volume
    }

    private func makePlayer(named name: String) -> AVAudioPlayer? {
        guard let url = BundleFile.url(name: name, extension: "caf", subdirectory: "Resources/Audio") else {
            return nil
        }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.volume = volume
        player.prepareToPlay()
        return player
    }
}
