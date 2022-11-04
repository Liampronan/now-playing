import AVFoundation
import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
       
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setupBackgroundAudio(for: application)
        return true
    }
    
    private func setupBackgroundAudio(for application: UIApplication) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }

        // register app for remote control events in order to handle play/pause/etc NowPlaying controls from lockscreen
        application.beginReceivingRemoteControlEvents()
    }
}
