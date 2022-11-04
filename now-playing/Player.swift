import AVFAudio
import Combine
import Foundation
import MediaPlayer
import Speech

// note: currently operating w/ assumption that MPNowPlaying center controls (e.g., rewind) are not nicely integrated with AVAudioSession -- so will probs need to define responses twice; investigate if there is a nicer way to bridge this.

// IN-PROGRESS:
    // - check if volume change notif works

// NEXT:
    // - apply rewind logic to app in background (maybe MPNowPlayInfoCenter)
    // - add title/info to (on-screen) player
    // - TODO [1015]: consider move this to error UI alert or something
    // - UI for clips
    // - debug UI - for logs, errors (dropdown alert from top; could be fun little library)
    // - expand beyond 10 seconds rewind; evaluate UX (e.g., compare rewind vs. play vs other interactions)
    // - auto-correct suggestions (for mis-transcribes)
    // - setup xcode cloud (FUN!)
    // - move to (simple) DI; find lib for this
    // - checkout spotify integration: https://github.com/spotify/ios-sdk
    // - is permission <key>NSSpeechRecognitionUsageDescription</key> needed? unclear. test more

// DONE:
  // - refactor transcription code to service; modernize async w/ async/await
  // - cleanup temp files; is there a better approach than what we're doing?
  // - remember position of last listened (so i can resume)
  // - add error handling for creating documents dir

// RESEARCH:
    // - CMTime ... what is CM (core media?) ... and other stuff like that

class Player: NSObject, ObservableObject {
    
    @Published var player = AVPlayer()
    // TODO: cleanup? is this needed?
//    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let audioSession = AVAudioSession.sharedInstance()
    private let streamURL = URL(string: "https://dts.podtrac.com/redirect.mp3/traffic.libsyn.com/secure/allinchamathjason/ALLIN-E98.mp3?dest-id=1928300")!
    private var cancellable: AnyCancellable?
    
    private var lastObservedTimes: LimitedArray<CMTime> = LimitedArray(maxSize: 2)
            
    override init() {
        super.init()
        loadMedia()
        addCommandCenterCommands()
        addPlayerObservers()
    }
    
    private func handleAVPlayerPaused() {
//        guard lastObservedTimes.count > 1 else { return }
//        let secondToLastObservedTime = lastObservedTimes[1]
//        let isPlayerRewinding = secondToLastObservedTime.seconds - player.currentTime().seconds >= 10
//
//        guard isPlayerRewinding else { return }
        print("paused ~~")
            
        guard let currentItemAsset = player.currentItem?.asset else {
            print("error unwrapping current item...")
            return
        }
        
        Task.init {
            do {
                let currentTime = player.currentTime()
                let prevTime = CMTimeSubtract(currentTime, .init(seconds: 10, preferredTimescale: currentTime.timescale))
                let clipRange = CMTimeRange(start: prevTime, end: currentTime)
                let transcribed = try await TranscribeService.transcribe(with: currentItemAsset, at: clipRange)
                print("transcribed:", transcribed)
            } catch {
                // TODO [1015]: consider move this to error UI alert or something
                print("error creating dir")
            }
        }
    }
    
    private func addCommandCenterCommands() {
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.addTarget { event in
            return .success
        }
        
        commandCenter.playCommand.isEnabled = true
        
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            self.player.play()
            return .success
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.addTarget { event in
//            let time = CMTimeMakeWithSeconds(10, preferredTimescale: Int)
//            player?.currentItem?.seek(to: .now - time)
           print("backward from cmd center....")
            
//            let seekDuration: Float64 = 10
//            let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
            
            return .success
        }
    }
    
    private func loadMedia() {
        let avAsset = AVURLAsset(url: streamURL)
        // setting delegate allows for remote url trimming ... not exactly sure if this is a great approach but works for now. https://stackoverflow.com/a/47954704
        avAsset.resourceLoader.setDelegate(self, queue: .main)
        let item = AVPlayerItem(asset: avAsset)
        self.player.replaceCurrentItem(with: item)
       
        let mostRecentTimeStamp = EpisodeTimeStampTracker.getLatestTime(forEpisodeURL: streamURL)
        player.seek(to: .init(seconds: mostRecentTimeStamp, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func addPlayerObservers() {
        cancellable = self.player.publisher(for: \.timeControlStatus).sink { [weak self] status in
            print("timecontrol status changed", status.rawValue)
            guard let self = self else { return }
            switch status {
            case .paused:
                self.handleAVPlayerPaused()
            case .playing, .waitingToPlayAtSpecifiedRate:
                return
            @unknown default:
                fatalError("unhandled case") // TODO: error handler
            }
        }
        
        
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.lastObservedTimes.insert(time, at: 0)
            EpisodeTimeStampTracker.storeLatestTime(forEpisodeURL: self.streamURL, time: time.seconds)
        }
    }
}

// conforming to this delegate here allows for remote urls to get trimmed via AVAssetExportSession
// (see: https://stackoverflow.com/a/47954704)
extension Player: AVAssetResourceLoaderDelegate { }
