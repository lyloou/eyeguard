import Foundation

/// 休息时随机展示的语录：内置条目 + `~/.eyeguard/rest-quotes.txt`（一行一句，可选）。
enum RestQuoteProvider {

    /// 用户自定义文件名，位于用户主目录下 `.eyeguard` 文件夹。
    private static let customFileName = "rest-quotes.txt"

    private static let builtIn: [String] = [
        "别等局面推着你走，自己先动起来。",
        "与其被动承受，不如主动破局。",
        "不要困在原地，先去找新的出路。",
        "别把选择权交给环境，主动做调整。",
        "不要只等问题发生，要提前创造转机。",
        "与其被动应对，不如主动调整路径。",
        "局面不利时，靠等不会变好，靠行动才会。",
        "不要被现状绑住，主动寻找新的可能。",
        "局势不会自动好转，改变要靠自己争取。",
        "与其等机会出现，不如自己打开局面。",
        "不要在消耗里硬扛，要主动为自己换打法。",
        "真正的出路，不是等来的，是主动找来的。",
        "与其停在被动位置，不如尽早转向主动选择。",
        "现状如果不理想，就别只承受，要开始调整。",
        "改变通常不会自己发生，需要主动推动。",
        "被动等待很少解决问题，主动调整才更有效。",
        "别把自己放在只能挨打的位置，往前走一步。",
        "先别抱着现状不放，试着换一种走法。",
        "不要等别人来改你的处境，你先动手改。",
        "真想脱困，就别只是熬，要开始找办法。",
        "面对困局，等待不是办法，主动调整才有机会。",
        "与其陷于被动，不如主动谋求改变。",
        "当环境无解时，更要主动重构自己的选择。",
        "改变现状的前提，是先停止被动承受。",
        "别傻等，得自己找路。",
        "不能老挨着，得想办法动一动。",
        "干等没用，得主动换个活法。",
        "别守着烂局面不动，能换就换。",
        "我们不能只停留在被动承接，要主动寻找突破口。",
        "不能等问题把空间压没了，得提前做调整。",
        "与其等外部给机会，不如主动创造条件。",
        "面对当前局面，继续被动消耗不是办法，必须主动求变。",
    ]

    /// 展开后的自定义语录文件路径（`~/...`）。
    private static func customFileURL() -> URL {
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        return home.appendingPathComponent(".eyeguard", isDirectory: true)
            .appendingPathComponent(customFileName, isDirectory: false)
    }

    /// 从 txt 读取非空且非 `#` 注释行；读失败或未设置则返回空数组。
    private static func customLines() -> [String] {
        let url = customFileURL()
        guard FileManager.default.isReadableFile(atPath: url.path) else { return [] }
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else { return [] }
        return text.split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }

    /// 返回一条随机语录；若无可用条目则退回内置首句（理论上不会发生）。
    static func randomQuote() -> String {
        let extras = customLines()
        let pool = extras.isEmpty ? builtIn : builtIn + extras
        return pool.randomElement() ?? builtIn[0]
    }
}
