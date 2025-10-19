import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private var timer: Timer?

    // MARK: - Setup
    func setupRecorder() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            // Create audio file URL
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            audioFileURL = audioFilename

            // Audio settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()

            return true
        } catch {
            print("Failed to setup audio recorder: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Recording Controls
    func startRecording() {
        guard setupRecorder() else { return }

        audioRecorder?.record()
        isRecording = true
        recordingDuration = 0

        // Start timer to update duration
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration = self.audioRecorder?.currentTime ?? 0
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false)
    }

    func cancelRecording() {
        stopRecording()
        if let url = audioFileURL {
            try? FileManager.default.removeItem(at: url)
            audioFileURL = nil
        }
    }

    // MARK: - Get Recording
    func getRecordingURL() -> URL? {
        return audioFileURL
    }

    // MARK: - Request Permissions
    static func requestRecordPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
            audioFileURL = nil
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Audio encoding error: \(error?.localizedDescription ?? "Unknown error")")
        audioFileURL = nil
    }
}
