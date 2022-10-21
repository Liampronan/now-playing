import MediaPlayer
import SwiftUI


class AppDelegate: NSObject, UIApplicationDelegate {
    let commandCenter = MPRemoteCommandCenter.shared()
    let streamURL = URL(string: "https://dts.podtrac.com/redirect.mp3/traffic.libsyn.com/secure/allinchamathjason/ALLIN-E98.mp3?dest-id=1928300")!
    var player: AVPlayer?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.beginReceivingRemoteControlEvents()
        
        return true
    }
    
    func setupPlayer() {
        let item = AVPlayerItem(url: streamURL)
        self.player = AVPlayer(playerItem: item)
        player!.allowsExternalPlayback = true
    }
    
    func play() {
        print("called play()")
    }
    
    func setupNowPlaying() {
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Helloooo worldddd"

        if let image = UIImage(systemName: "radio") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentItem?.currentTime().seconds ?? ""
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player?.currentItem?.asset.duration.seconds ?? ""

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

@main
struct now_playingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    
}
