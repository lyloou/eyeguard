import Foundation
import AudioToolbox

/// 音效管理器 — 使用系统音效 ID
class SoundManager {

    static let shared = SoundManager()

    // 系统音效 ID
    private enum SoundID {
        static let restStart: SystemSoundID = 1013  // Glass
        static let restEnd: SystemSoundID = 1016    // Pop
        static let workStart: SystemSoundID = 1104   // Funk
    }

    private init() {}

    /// 工作结束（休息开始）
    func playRestStart() {
        guard Settings.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(SoundID.restStart)
    }

    /// 休息结束（继续工作）
    func playRestEnd() {
        guard Settings.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(SoundID.restEnd)
    }

    /// 工作开始
    func playWorkStart() {
        guard Settings.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(SoundID.workStart)
    }
}
