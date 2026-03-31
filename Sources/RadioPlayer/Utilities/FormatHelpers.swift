import Foundation

public func formatDuration(_ totalSeconds: Double) -> String {
    let hours = Int(totalSeconds) / 3600
    let minutes = (Int(totalSeconds) % 3600) / 60
    let seconds = Int(totalSeconds) % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%d:%02d", minutes, seconds)
    }
}

public func formatDuration(fromString string: String?) -> String? {
    guard let string, let seconds = Double(string) else { return nil }
    return formatDuration(seconds)
}

public func stripHTML(_ html: String?) -> String? {
    guard let html else { return nil }
    guard html.contains("<") else {
        return decodeHTMLEntities(html)
    }

    let stripped = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    return decodeHTMLEntities(stripped)
}

private func decodeHTMLEntities(_ string: String) -> String {
    var result = string
    let entities: [(String, String)] = [
        ("&amp;", "&"),
        ("&lt;", "<"),
        ("&gt;", ">"),
        ("&quot;", "\""),
        ("&#39;", "'"),
        ("&apos;", "'"),
        ("&nbsp;", " "),
    ]
    for (entity, replacement) in entities {
        result = result.replacingOccurrences(of: entity, with: replacement)
    }
    return result
}
