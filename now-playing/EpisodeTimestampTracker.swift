import Foundation
import SwiftyUserDefaults

struct EpisodeTimeStampTracker {
    static func storeLatestTime(forEpisodeURL url: URL, time: Double) {
        Defaults[\.lastLastenedTimeStamps][url.absoluteString] = time
    }
    
    static func getLatestTime(forEpisodeURL url: URL) -> Double {
        return Defaults[\.lastLastenedTimeStamps][url.absoluteString, default: 0]
    }
    
}
