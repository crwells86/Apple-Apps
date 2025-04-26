extension Int {
    var podcastDurationString: String {
        let totalSeconds = self / 1_000
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)h \(String(format: "%02d", minutes))m"
        } else if minutes < 10 {
            return "\(minutes)m \(String(format: "%02d", seconds))s"
        } else {
            return "\(minutes)m"
        }
    }
}
