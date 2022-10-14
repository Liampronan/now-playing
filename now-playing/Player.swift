import AVFAudio
import Foundation
import MediaPlayer
import Speech

// note: currently operating w/ assumption that MPNowPlaying center controls (e.g., rewind) are not nicely integrated with AVAudioSession -- so will probs need to define responses twice; investigate if there is a nicer way to bridge this.

// TODO: checkout spotify integration: https://github.com/spotify/ios-sdk

// NEXT:
    // - apply rewind logic to MPNowPlayInfoCenter
    // - expand beyond 10 seconds rewind; evaluate UX (e.g., compare rewind vs. play vs other interactions)

// RESEARCH:
    // - CMTime ... what is CM (core media?) ... and other stuff like that
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
        player.allowsExternalPlayback = true

        NotificationCenter.default.addObserver(self, selector: #selector(handleAVPlayerTimeJumpedNotification), name: AVPlayerItem.timeJumpedNotification, object: nil)
        
        setInfo()
        setupNowPlaying()
        
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.lastObservedTimes.insert(time, at: 0)

        }
    }
    
    @objc private func handleAVPlayerTimeJumpedNotification(notif: Notification) {
        guard lastObservedTimes.count > 1 else { return }
        let secondToLastObservedTime = lastObservedTimes[1]
        
        if secondToLastObservedTime.seconds - player.currentTime().seconds >= 10 {
            print("rewind ~~")
            
            guard let currentItemAsset = player.currentItem?.asset else {
                print("error unwrapping current item...")
                return
            }
            
//            let avComposition = AVMutableComposition(url: <#T##URL#>)
            guard let exportSession = AVAssetExportSession(asset: currentItemAsset, presetName: AVAssetExportPresetAppleM4A) else {
                print("error creating export session...")
                return
            }
            
            exportSession.determineCompatibleFileTypes { fileTypes in
                print("compatabile file types: ", fileTypes)
            }
            
            exportSession.outputURL = createUrlInAppDD("tesing112234.m4a")
            exportSession.outputFileType = .m4a
            exportSession.timeRange = CMTimeRange(start: lastObservedTimes[0], end: secondToLastObservedTime)
            print("timerange: ", exportSession.timeRange)
            print("timerange seconds: ", lastObservedTimes[0].seconds, lastObservedTimes[1].seconds)
                
            exportSession.exportAsynchronously(completionHandler: {
                        switch exportSession.status {
                        case .failed:
                            print("Export failed: \(exportSession.error!.localizedDescription)")
                        case .cancelled:
                            print("Export canceled")
                        default:
                            print("Successfully trimmed audio", exportSession.outputURL)
                            let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
                            let request = SFSpeechURLRecognitionRequest(url: exportSession.outputURL!)
                            
                            request.shouldReportPartialResults = false

                            if (recognizer?.isAvailable)! {

                                recognizer?.recognitionTask(with: request) { result, error in
                                    guard error == nil else { print("Error: \(error!)"); return }
                                    guard let result = result else { print("No result!"); return }

                                    print(result.bestTranscription.formattedString)
                                }
                            } else {
                                print("Device doesn't support speech recognition")
                            }
                            
//                            DispatchQueue.main.async(execute: {
//                                finished(furl)
//                            })
                        }
                    })
            
            
            
        }
    }
    
    
    private func createUrlInAppDD(_ filename: String) -> URL {
        
        let dirPathNoScheme = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String

        //add directory path file Scheme;  some operations fail w/out it
        let dirPath = "file://\(dirPathNoScheme)"
        //name your file, make sure you get the ext right .mp3/.wav/.m4a/.mov/.whatever
        let pathArray = [dirPath, filename]
        let path = URL(string: pathArray.joined(separator: "/"))

        //use a guard since the result is an optional
        guard let filePath = path else {
            // TODO: better error handling .... 
            print("filepath creation failed ~~~")
            //if it fails do this stuff:
            return URL(string: "choose how to handle error here")!
        }
        print("filepath created ~~~", filePath)
        //if it works return the filePath
        return filePath
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
