import AVFAudio
import AVFoundation
import Speech

struct TranscribeService {
    enum TranscribeError: Error {
        case directoryCreation
        case createExportSession
        case transcription(String)
        case speechRecognizerUnavailable
        case unrecognizedAudio
    }
    
    static func transcribe(with asset: AVAsset, at timeRange: CMTimeRange) async throws -> AudioTranscription {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw TranscribeError.createExportSession
        }
        exportSession.outputFileType = .m4a
        exportSession.timeRange = timeRange
        
        do {
            let tempFileUrl = try createUrlInAppDD()
            exportSession.outputURL = tempFileUrl
            
            await exportSession.export()
            
            let clippedAudio = try await recognize(from: tempFileUrl)
            
            defer {
                do {
                    try FileManager.default.removeItem(at: tempFileUrl)
                } catch (let e) {
                    print("error deleting file", e)
                }
            }
                        
            return clippedAudio
        } catch let e {
            throw TranscribeError.transcription(e.localizedDescription)
        }
    }
    
    private static func recognize(from url: URL) async throws -> AudioTranscription {
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),  recognizer.isAvailable else {
            throw TranscribeError.speechRecognizerUnavailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                guard error == nil else {
                    continuation.resume(throwing: error!)
                    return
                }
                
                guard let result = result else {
                    continuation.resume(throwing: TranscribeError.unrecognizedAudio)
                    return
                }

                let audioTranscription = AudioTranscription(text: result.bestTranscription.formattedString)
                continuation.resume(returning: audioTranscription)
            }
        }
    }
    
    private static func createUrlInAppDD(_ filename: String = "tempfile-\(UUID().uuidString).m4a") throws -> URL  {

        let dirPath = URL(fileURLWithPath: NSTemporaryDirectory(),
                          isDirectory: true).absoluteString
        
        // note: filename should include extension
        let pathArray = [dirPath, filename]
        let path = URL(string: pathArray.joined(separator: ""))

        guard let filePath = path else {
            throw TranscribeError.directoryCreation
        }
        
        return filePath
    }
    
    // fire and forget this; just helps for cleanup/re-use of temp files
    private func cleanupTempFile(at tempFileUrl: URL ) {
        do {
            try FileManager.default.removeItem(at: tempFileUrl)
        } catch (let e) {
            print("error deleting file", e)
        }
    }
}



