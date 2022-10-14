import AVFAudio
import Foundation
import MediaPlayer


// note: currently operating w/ assumption that MPNowPlaying center controls (e.g., rewind) are not nicely integrated with AVAudioSession -- so will probs need to define responses twice; investigate if there is a nicer way to bridge this.
class Player: ObservableObject {
    
    @Published var player = AVPlayer()
    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let audioSession = AVAudioSession.sharedInstance()
    private let streamURL = URL(string: "https://dts.podtrac.com/redirect.mp3/traffic.libsyn.com/secure/allinchamathjason/ALLIN-E98.mp3?dest-id=1928300")!
            
    init() {
        let item = AVPlayerItem(url: streamURL)
        self.player.replaceCurrentItem(with: item)
        player.allowsExternalPlayback = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAVPlayerTimeJumpedNotification), name: AVPlayerItem.timeJumpedNotification, object: nil)
        
        setInfo()
        setupNowPlaying()
    }
    
    @objc private func handleAVPlayerTimeJumpedNotification(notif: Notification) {
        print("current time of player is~~~~", player.currentTime().seconds)
    }
    
    
    private func setInfo() {
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.addTarget { event in
            return .success
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.addTarget { event in
//            let time = CMTimeMakeWithSeconds(10, preferredTimescale: Int)
//            player?.currentItem?.seek(to: .now - time)
           print("backward....")
            
//            let seekDuration: Float64 = 10
//            let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
            
            return .success
        }
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
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentItem?.currentTime().seconds ?? ""
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.currentItem?.asset.duration.seconds ?? ""

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    
}
