import MediaPlayer
import SwiftUI


class AppDelegate: NSObject, UIApplicationDelegate {
    let commandCenter = MPRemoteCommandCenter.shared()
    let streamURL = URL(string: "https://dts.podtrac.com/redirect.mp3/traffic.libsyn.com/secure/allinchamathjason/ALLIN-E98.mp3?dest-id=1928300")!
    var player: AVPlayer?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.beginReceivingRemoteControlEvents()
        
        
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.addTarget { event in
            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.addTarget { event in
//            let time = CMTimeMakeWithSeconds(10, preferredTimescale: Int)
//            player?.currentItem?.seek(to: .now - time)
            guard let player = self.player else {
                print("failed to unwrap player...")
                return .commandFailed
            }
            
            let seekDuration: Float64 = 10
            let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
            
            return .success
        }

// ~~ this may be a nicer UI than skip fwd/back but no idea how to implement it atm.
//        commandCenter.bookmarkCommand.isEnabled = true
//        commandCenter.bookmarkCommand.addTarget { event in
//            print("liked....")
//            return .success
//        }
//
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { event in
            self.play()
            return .success
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            self.player?.pause()
            return .success
        }
        
        setupPlayer()
        setupNowPlaying()
//        player!.play()
        
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
