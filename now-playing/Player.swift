import AVFAudio
import Foundation
import MediaPlayer
import Speech
import SwiftyUserDefaults

// note: currently operating w/ assumption that MPNowPlaying center controls (e.g., rewind) are not nicely integrated with AVAudioSession -- so will probs need to define responses twice; investigate if there is a nicer way to bridge this.

// TODO: checkout spotify integration: https://github.com/spotify/ios-sdk

// IN-PROGRESS:

    // - check if volume change notif works

// NEXT:
    
    // - apply rewind logic to MPNowPlayInfoCenter
    // - TODO [1015]: consider move this to error UI alert or something
    // - UI for clips
    // - debug UI - for logs, errors (dropdown alert from top; could be fun little library)
    // - expand beyond 10 seconds rewind; evaluate UX (e.g., compare rewind vs. play vs other interactions)

// DONE:
  // - refactor transcription code to service; modernize async w/ async/await
  // - cleanup temp files; is there a better approach than what we're doing?
  // - remember position of last listened (so i can resume)
  // - add error handling for creating documents dir

// RESEARCH:
    // - CMTime ... what is CM (core media?) ... and other stuff like that

// TODO: cleanup; move to own file; consider DI
struct EpisodeTimeStampTracker {
    static func storeLatestTime(forEpisodeURL url: URL, time: Double) {
        Defaults[\.lastLastenedTimeStamps][url.absoluteString] = time
    }
    
    static func getLatestTime(forEpisodeURL url: URL) -> Double {
        return Defaults[\.lastLastenedTimeStamps][url.absoluteString, default: 0]
    }
    
}

extension DefaultsKeys {
    var lastLastenedTimeStamps: DefaultsKey<[String: Double]> { .init("lastLastenedTimeStamps", defaultValue: [:])}
}


class Player: NSObject, ObservableObject {
    
    @Published var player = AVPlayer()
    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let audioSession = AVAudioSession.sharedInstance()
    private let streamURL = URL(string: "https://dts.podtrac.com/redirect.mp3/traffic.libsyn.com/secure/allinchamathjason/ALLIN-E98.mp3?dest-id=1928300")!
    
    private var lastObservedTimes: LimitedArray<CMTime> = LimitedArray(maxSize: 2)
            
    override init() {
        super.init()
        let avAsset = AVURLAsset(url: streamURL)
        // setting delegate allows for remote url trimming ... not exactly sure if this is a great approach but works for now. https://stackoverflow.com/a/47954704
        avAsset.resourceLoader.setDelegate(self, queue: .main)
        let item = AVPlayerItem(asset: avAsset)
        
        self.player.replaceCurrentItem(with: item)
        let mostRecentTimeStamp = EpisodeTimeStampTracker.getLatestTime(forEpisodeURL: streamURL)
        player.seek(to: .init(seconds: mostRecentTimeStamp, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
        player.allowsExternalPlayback = true

        NotificationCenter.default.addObserver(self, selector: #selector(handleAVPlayerTimeJumpedNotification), name: AVPlayerItem.timeJumpedNotification, object: nil)
        
        setInfo()
        setupNowPlaying()
        
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.lastObservedTimes.insert(time, at: 0)
            EpisodeTimeStampTracker.storeLatestTime(forEpisodeURL: self.streamURL, time: time.seconds)
        }
    }
    
    @objc private func handleAVPlayerTimeJumpedNotification(notif: Notification) {
        guard lastObservedTimes.count > 1 else { return }
        let secondToLastObservedTime = lastObservedTimes[1]
        let isPlayerRewinding = secondToLastObservedTime.seconds - player.currentTime().seconds >= 10
        
        guard isPlayerRewinding else { return }
            print("rewind ~~")
            
        guard let currentItemAsset = player.currentItem?.asset else {
            print("error unwrapping current item...")
            return
        }
        
        Task.init {
            do {
                let clipRange = CMTimeRange(start: lastObservedTimes[0], end: secondToLastObservedTime)
                let transcribed = try await TranscribeService.transcribe(with: currentItemAsset, at: clipRange)
                print("transcribed:", transcribed)
            } catch {
                // TODO [1015]: consider move this to error UI alert or something
                print("error creating dir")
            }
        }
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
//           print("backward....")
            
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

// conforming to this delegate here allows for remote urls to get trimmed via AVAssetExportSession
// (see: https://stackoverflow.com/a/47954704)
extension Player: AVAssetResourceLoaderDelegate {}
