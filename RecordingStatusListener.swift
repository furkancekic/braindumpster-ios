import Foundation
import FirebaseFirestore
import Combine

/// Service to listen for recording status changes in Firestore
class RecordingStatusListener: ObservableObject {
    @Published var recording: Recording?
    @Published var isListening = false

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    /// Start listening for recording updates
    func startListening(recordingId: String, userId: String) {
        guard !isListening else { return }

        print("👂 [RecordingStatusListener] Starting to listen for recording: \(recordingId)")
        isListening = true

        let docRef = db.collection("users")
            .document(userId)
            .collection("recordings")
            .document(recordingId)

        listener = docRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ [RecordingStatusListener] Error listening to recording: \(error)")
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                print("⚠️ [RecordingStatusListener] Recording document not found")
                return
            }

            do {
                // Decode Firestore document to Recording model
                let recording = try snapshot.data(as: Recording.self)

                print("📥 [RecordingStatusListener] Recording updated:")
                print("   Status: \(recording.status.rawValue)")
                print("   Title: \(recording.title)")

                // Update published recording
                DispatchQueue.main.async {
                    self.recording = recording
                }

                // Auto-stop listening when completed or failed
                // Delay stopping to ensure the update is fully processed
                if recording.status == .completed || recording.status == .failed {
                    print("✅ [RecordingStatusListener] Recording finished (\(recording.status.rawValue)), will stop listener shortly")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.stopListening()
                    }
                }

            } catch {
                print("❌ [RecordingStatusListener] Failed to decode recording: \(error)")
            }
        }
    }

    /// Stop listening for updates
    func stopListening() {
        guard isListening else { return }

        print("🛑 [RecordingStatusListener] Stopping listener")
        listener?.remove()
        listener = nil
        isListening = false
    }

    deinit {
        stopListening()
    }
}
