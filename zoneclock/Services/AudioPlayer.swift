//
//  AudioPlayer.swift
//  zoneclock
//
//  Created by Zone Clock CDD System on 2025/1/2.
//  Audio playback manager
//

import Foundation
import AVFoundation

/// 音频播放管理器
class AudioPlayer {
    // MARK: - Singleton
    static let shared = AudioPlayer()

    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?

    // MARK: - Initialization
    private init() {
        setupAudioSession()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Play Methods

    /// 播放微休息声音（根据用户设置）
    func playMicroBreakSound() {
        let settings = Settings.load()
        let soundType = settings.soundSettings.soundType
        print("🎵 Playing micro break sound type: \(soundType.displayName) (\(soundType.fileName))")
        playSound(fileName: soundType.fileName, volume: settings.soundSettings.volume)
    }

    /// 播放大休息声音（西藏钵）
    func playLongBreakSound() {
        let settings = Settings.load()
        print("🎵 Playing long break sound: xizangbo")
        playSound(fileName: "xizangbo", volume: settings.soundSettings.volume)
    }

    /// 播放周期完成声音（西藏钵）
    func playCycleCompleteSound() {
        let settings = Settings.load()
        print("🎵 Playing cycle complete sound: xizangbo")
        playSound(fileName: "xizangbo", volume: settings.soundSettings.volume)
    }

    // MARK: - Private Methods

    /// 播放指定的声音文件
    private func playSound(fileName: String, volume: Float? = nil) {
        // 查找音频文件
        guard let url = findAudioFile(fileName: fileName) else {
            print("Audio file not found: \(fileName)")
            return
        }

        do {
            // 创建音频播放器
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume ?? 0.7
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            print("✅ Playing sound: \(fileName) at volume \(volume ?? 0.7)")
        } catch {
            print("❌ Failed to play sound \(fileName): \(error)")
        }
    }

    /// 查找音频文件
    private func findAudioFile(fileName: String) -> URL? {
        print("🔍 Searching for audio file: \(fileName)")

        // 尝试不同的扩展名
        let extensions = ["MP3", "mp3", "m4a", "wav"]

        for ext in extensions {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                print("✅ Found audio file: \(url.path)")
                return url
            }
        }

        // 尝试在 audio 子目录中查找
        for ext in extensions {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: "audio") {
                print("✅ Found audio file in subdirectory: \(url.path)")
                return url
            }
        }

        print("❌ Audio file not found: \(fileName)")
        return nil
    }

    // MARK: - Control Methods

    /// 停止播放
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    /// 暂停播放
    func pause() {
        audioPlayer?.pause()
    }

    /// 恢复播放
    func resume() {
        audioPlayer?.play()
    }

    /// 设置音量
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }
}
