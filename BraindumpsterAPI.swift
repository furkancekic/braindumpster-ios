import Foundation

class BraindumpsterAPI {
    static let shared = BraindumpsterAPI()

    // MARK: - Configuration
    // Production API - braindumpster.io domain
    private let baseURL = "https://api.braindumpster.io/api"

    // Local development: http://localhost:5001/api
    // Old server: http://57.129.81.193:5001/api

    private init() {}

    // MARK: - Send Audio Message
    func sendAudioMessage(audioFileURL: URL, conversationId: String? = nil) async throws -> AudioMessageResponse {
        let endpoint = "\(baseURL)/chat/send-audio"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add audio file
        let audioData = try Data(contentsOf: audioFileURL)
        let filename = audioFileURL.lastPathComponent
        let mimeType = getMimeType(for: audioFileURL)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add conversation_id if provided
        if let conversationId = conversationId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"conversation_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(conversationId)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 API Response: \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Decode response
        do {
            let audioResponse = try JSONDecoder().decode(AudioMessageResponse.self, from: data)
            print("✅ Successfully decoded response")
            return audioResponse
        } catch {
            print("❌ Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key: \(key.stringValue) - \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: \(type) - \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: \(type) - \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
            throw error
        }
    }

    // MARK: - Send Text Message
    func sendTextMessage(message: String, conversationId: String? = nil) async throws -> ChatMessageResponse {
        let endpoint = "\(baseURL)/chat/send"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create body
        var body: [String: Any] = ["message": message]
        if let conversationId = conversationId {
            body["conversation_id"] = conversationId
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Decode response
        let chatResponse = try JSONDecoder().decode(ChatMessageResponse.self, from: data)
        return chatResponse
    }

    // MARK: - Get User Tasks
    func getUserTasks(userId: String, status: String? = nil) async throws -> TasksResponse {
        var endpoint = "\(baseURL)/tasks/user/\(userId)"

        // Add status filter if provided
        if let status = status {
            endpoint += "?status=\(status)"
        }

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Decode response
        let tasksResponse = try JSONDecoder().decode(TasksResponse.self, from: data)
        return tasksResponse
    }

    // MARK: - Approve Tasks
    func approveTasks(taskIds: [String]) async throws -> ApproveResponse {
        let endpoint = "\(baseURL)/tasks/approve"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create body
        let body: [String: Any] = ["task_ids": taskIds]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Decode response
        let approveResponse = try JSONDecoder().decode(ApproveResponse.self, from: data)
        return approveResponse
    }

    // MARK: - Create Tasks
    func createTasks(tasks: [TaskSuggestion], suggestions: [Suggestion]? = nil, autoApprove: Bool = true) async throws -> CreateTasksResponse {
        print("🔵 createTasks: Called with \(tasks.count) tasks, \(suggestions?.count ?? 0) suggestions, autoApprove: \(autoApprove)")
        let endpoint = "\(baseURL)/tasks/create"

        // Get Firebase auth token
        print("🔵 createTasks: Getting Firebase auth token")
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    print("🔵 createTasks: Got Firebase token")
                    continuation.resume(returning: token)
                case .failure(let error):
                    print("❌ createTasks: Failed to get Firebase token: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("🔵 createTasks: Starting to convert \(tasks.count) tasks")

        // Convert TaskSuggestion to API format
        let tasksData = tasks.map { task -> [String: Any] in
            var taskDict: [String: Any] = [
                "title": task.title,
                "description": task.description,
                "priority": task.priority,
                "category": task.category
            ]

            if let dueDate = task.dueDate {
                taskDict["due_date"] = dueDate
            }

            if let estimatedDuration = task.estimatedDuration {
                taskDict["estimated_duration"] = estimatedDuration
            }

            // Add reminders with automatic spacing for duplicates
            let adjustedReminders = adjustReminderTimesIfNeeded(task.reminders)
            let reminders = adjustedReminders.map { reminder -> [String: Any] in
                return [
                    "reminder_time": reminder.reminderTime,
                    "message": reminder.message,
                    "type": reminder.type
                ]
            }
            taskDict["reminders"] = reminders

            // Add suggestions if provided (same suggestions for all tasks from this conversation)
            if let suggestions = suggestions {
                let suggestionsData = suggestions.map { suggestion -> [String: Any] in
                    var suggestionDict: [String: Any] = [
                        "type": suggestion.type,
                        "title": suggestion.title,
                        "description": suggestion.description
                    ]
                    if let reasoning = suggestion.reasoning {
                        suggestionDict["reasoning"] = reasoning
                    }
                    return suggestionDict
                }
                taskDict["suggestions"] = suggestionsData
            }

            return taskDict
        }

        print("🔵 createTasks: Converted tasks data, creating body")

        // Create body
        let body: [String: Any] = [
            "tasks": tasksData,
            "auto_approve": autoApprove
        ]

        print("🔵 createTasks: About to serialize JSON")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("🔵 createTasks: JSON serialization successful")
        } catch {
            print("❌ createTasks: JSON serialization failed: \(error)")
            throw error
        }

        // Debug: Print request body
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Create Tasks Request Body: \(bodyString)")
        }

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Debug: Print response
        print("📥 Create Tasks Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Create Tasks Response Body: \(responseString)")
        }

        guard httpResponse.statusCode == 201 else {
            print("❌ createTasks: HTTP status code is \(httpResponse.statusCode), expected 201")
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Decode response
        print("🔵 createTasks: About to decode response")
        do {
            let createResponse = try JSONDecoder().decode(CreateTasksResponse.self, from: data)
            print("✅ createTasks: Successfully decoded response")
            return createResponse
        } catch {
            print("❌ createTasks: Failed to decode response: \(error)")
            throw error
        }
    }

    // MARK: - Delete Task
    func deleteTask(taskId: String) async throws {
        let endpoint = "\(baseURL)/tasks/\(taskId)"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Update Task Status
    func updateTaskStatus(taskId: String, status: String) async throws {
        let endpoint = "\(baseURL)/tasks/\(taskId)"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create body
        let body: [String: Any] = ["status": status]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Delete Reminder
    func deleteReminder(taskId: String, reminderId: String) async throws {
        let endpoint = "\(baseURL)/tasks/\(taskId)/reminders/\(reminderId)"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Update Reminder
    func updateReminder(taskId: String, reminderId: String, reminderTime: String, message: String, recurrence: String? = nil, priority: String? = nil) async throws {
        let endpoint = "\(baseURL)/tasks/\(taskId)/reminders/\(reminderId)"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create request body
        var body: [String: Any] = [
            "reminder_time": reminderTime,
            "message": message
        ]

        // Add recurrence if provided
        if let recurrence = recurrence {
            body["recurrence"] = recurrence
        }

        // Add priority if provided
        if let priority = priority {
            body["priority"] = priority
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Update Task
    func updateTask(taskId: String, dueDate: String? = nil, time: String? = nil, title: String? = nil, description: String? = nil, priority: String? = nil) async throws {
        let endpoint = "\(baseURL)/tasks/\(taskId)"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create body with only provided fields
        var body: [String: Any] = [:]
        if let dueDate = dueDate {
            body["due_date"] = dueDate
        }
        if let time = time {
            body["time"] = time
        }
        if let title = title {
            body["title"] = title
        }
        if let description = description {
            body["description"] = description
        }
        if let priority = priority {
            body["priority"] = priority
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Update User Profile
    func updateUserProfile(profile: UserProfile) async throws {
        let endpoint = "\(baseURL)/auth/profile"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode profile
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(profile)

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Get User Profile
    func getUserProfile() async throws -> UserProfile {
        let endpoint = "\(baseURL)/auth/profile"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Decode response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let profile = try decoder.decode(UserProfile.self, from: data)
        return profile
    }

    // MARK: - Register User
    func registerUser(email: String, password: String, displayName: String) async throws -> RegisterResponse {
        let endpoint = "\(baseURL)/auth/register"

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create body
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "display_name": displayName,
            "timezone": TimeZone.current.identifier
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        // Decode response
        let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
        return registerResponse
    }

    // MARK: - Ensure User Exists (for OAuth users)
    func ensureUserExists(displayName: String?) async throws {
        let endpoint = "\(baseURL)/auth/ensure-user"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create body
        let body: [String: Any] = [
            "display_name": displayName ?? "",
            "timezone": TimeZone.current.identifier
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Accept both 200 (already exists) and 201 (created)
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        print("✅ User synced with backend successfully")
    }

    // MARK: - Export User Data
    func exportUserData() async throws -> Data {
        // Get user profile
        let profile = try await getUserProfile()

        // Get all tasks (without status filter to get all tasks)
        guard let userId = AuthService.shared.user?.uid else {
            throw APIError.unauthorized
        }
        let tasksResponse = try await getUserTasks(userId: userId)

        // Create export data structure
        let exportData: [String: Any] = [
            "export_date": ISO8601DateFormatter().string(from: Date()),
            "user_profile": [
                "display_name": profile.displayName ?? "",
                "email": AuthService.shared.user?.email ?? "",
                "birth_date": profile.birthDate ?? "",
                "bio": profile.bio ?? ""
            ],
            "tasks": tasksResponse.tasks.map { task in
                return [
                    "id": task.id,
                    "title": task.title,
                    "description": task.description,
                    "status": task.status,
                    "priority": task.priority,
                    "category": task.category ?? "",
                    "due_date": task.dueDate ?? "",
                    "estimated_duration": task.estimatedDuration ?? 0,
                    "created_at": task.createdAt ?? "",
                    "updated_at": task.updatedAt ?? "",
                    "reminders": task.reminders?.map { reminder in
                        return [
                            "id": reminder.id,
                            "reminder_time": reminder.reminderTime,
                            "message": reminder.message,
                            "sent": reminder.sent ?? false
                        ]
                    } ?? []
                ]
            },
            "statistics": [
                "total_tasks": tasksResponse.count,
                "completed_tasks": tasksResponse.tasks.filter { $0.status == "completed" }.count,
                "pending_tasks": tasksResponse.tasks.filter { $0.status == "pending" }.count,
                "in_progress_tasks": tasksResponse.tasks.filter { $0.status == "in_progress" }.count
            ]
        ]

        // Convert to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        return jsonData
    }

    // MARK: - Delete Account
    func deleteAccount() async throws {
        let endpoint = "\(baseURL)/users/me"

        // Get Firebase auth token
        let authToken = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Send request
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Failed to delete account. Server returned status code: \(httpResponse.statusCode)")
        }

        print("✅ Account deleted successfully")
    }

    // MARK: - Register FCM Token
    func registerFCMToken(token: String) async throws {
        let endpoint = "\(baseURL)/notifications/register-token"

        // Get Firebase auth token
        let authToken = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "fcm_token": token
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📤 Registering FCM token with backend...")

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        print("✅ FCM token registered successfully")
    }

    // MARK: - Helper Methods

    // Adjust reminder times to avoid duplicates - spread them 30 seconds apart if they're scheduled at the same time
    private func adjustReminderTimesIfNeeded(_ reminders: [ReminderSuggestion]) -> [ReminderSuggestion] {
        guard reminders.count > 1 else { return reminders }

        // Sort reminders by time
        let sorted = reminders.sorted { r1, r2 in
            r1.reminderTime < r2.reminderTime
        }

        var adjusted: [ReminderSuggestion] = []
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        dateFormatter.timeZone = TimeZone.current

        // Alternative formats
        let formatWithSeconds = DateFormatter()
        formatWithSeconds.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatWithSeconds.timeZone = TimeZone.current

        let formatWithoutSeconds = DateFormatter()
        formatWithoutSeconds.dateFormat = "yyyy-MM-dd HH:mm"
        formatWithoutSeconds.timeZone = TimeZone.current

        for (index, reminder) in sorted.enumerated() {
            if index == 0 {
                adjusted.append(reminder)
                continue
            }

            // Parse both current and previous reminder times (try multiple formats)
            let currentDate = dateFormatter.date(from: reminder.reminderTime)
                ?? formatWithSeconds.date(from: reminder.reminderTime)
                ?? formatWithoutSeconds.date(from: reminder.reminderTime)

            let previousDate = dateFormatter.date(from: adjusted[index - 1].reminderTime)
                ?? formatWithSeconds.date(from: adjusted[index - 1].reminderTime)
                ?? formatWithoutSeconds.date(from: adjusted[index - 1].reminderTime)

            guard let currentDate = currentDate, let previousDate = previousDate else {
                // If parsing fails, just add the reminder as is
                adjusted.append(reminder)
                continue
            }

            // If times are the same or less than 30 seconds apart, add 30 seconds to current
            let timeDifference = currentDate.timeIntervalSince(previousDate)
            if timeDifference < 30 {
                let newDate = previousDate.addingTimeInterval(30)
                let newTimeString = formatWithSeconds.string(from: newDate)

                // Create adjusted reminder
                let adjustedReminder = ReminderSuggestion(
                    reminderTime: newTimeString,
                    message: reminder.message,
                    type: reminder.type
                )
                adjusted.append(adjustedReminder)

                print("⚠️ Adjusted reminder time from \(reminder.reminderTime) to \(newTimeString) to avoid duplicate")
            } else {
                adjusted.append(reminder)
            }
        }

        return adjusted
    }

    private func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "m4a":
            return "audio/m4a"
        case "mp3":
            return "audio/mp3"
        case "wav":
            return "audio/wav"
        case "aac":
            return "audio/aac"
        default:
            return "audio/m4a"
        }
    }
}

// MARK: - API Models
struct AudioMessageResponse: Codable {
    let conversationId: String
    let response: AIResponse?
    let transcribedText: String?
    let tasks: [TaskSuggestion]
    let confidence: Double?
    let audioStored: Bool?
    let messageCount: Int?

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case response
        case transcribedText = "transcribed_text"
        case tasks
        case confidence
        case audioStored = "audio_stored"
        case messageCount = "message_count"
    }
}

struct ChatMessageResponse: Codable {
    let conversationId: String
    let response: AIResponse
    let messageCount: Int

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case response
        case messageCount = "message_count"
    }
}

struct AIResponse: Codable {
    let success: Bool
    let transcription: String?
    let analysis: Analysis?
    let tasks: [TaskSuggestion]
    let suggestions: [Suggestion]?
    let detectedLanguage: String?

    enum CodingKeys: String, CodingKey {
        case success
        case transcription
        case analysis
        case tasks
        case suggestions
        case detectedLanguage = "detected_language"
    }
}

struct Suggestion: Codable, Identifiable {
    let id = UUID()
    let type: String
    let title: String
    let description: String
    let reasoning: String?

    enum CodingKeys: String, CodingKey {
        case type
        case title
        case description
        case reasoning
    }
}

struct Analysis: Codable {
    let userIntent: String?
    let queryType: String?
    let keyPriorities: [String]?
    let timeFrame: String?
    let complexityAssessment: String?

    enum CodingKeys: String, CodingKey {
        case userIntent = "user_intent"
        case queryType = "query_type"
        case keyPriorities = "key_priorities"
        case timeFrame = "time_frame"
        case complexityAssessment = "complexity_assessment"
    }
}

struct TaskSuggestion: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let priority: String
    let category: String
    let estimatedDuration: Int?
    let dueDate: String?
    let reminders: [ReminderSuggestion]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case priority
        case category
        case estimatedDuration = "estimated_duration"
        case dueDate = "due_date"
        case reminders
    }

    // Custom decoder to generate ID if not present and handle string/int for estimatedDuration
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Generate UUID if id is not present
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.priority = try container.decode(String.self, forKey: .priority)
        self.category = try container.decode(String.self, forKey: .category)

        // Handle estimated_duration as either Int or String
        if let durationInt = try? container.decode(Int.self, forKey: .estimatedDuration) {
            self.estimatedDuration = durationInt
        } else if let durationString = try? container.decode(String.self, forKey: .estimatedDuration),
                  let durationInt = Int(durationString) {
            self.estimatedDuration = durationInt
        } else {
            self.estimatedDuration = nil
        }

        // Handle due_date - convert "null" string to nil
        if let dueDateString = try? container.decode(String.self, forKey: .dueDate),
           dueDateString != "null" && !dueDateString.isEmpty {
            self.dueDate = dueDateString
        } else {
            self.dueDate = nil
        }

        self.reminders = (try? container.decode([ReminderSuggestion].self, forKey: .reminders)) ?? []
    }
}

struct ReminderSuggestion: Codable, Identifiable, Hashable {
    var id: String { reminderTime }
    let reminderTime: String
    let message: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case reminderTime = "reminder_time"
        case message
        case type
    }

    static func == (lhs: ReminderSuggestion, rhs: ReminderSuggestion) -> Bool {
        lhs.reminderTime == rhs.reminderTime
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(reminderTime)
    }
}

struct RegisterResponse: Codable {
    let message: String
    let uid: String
}

struct ErrorResponse: Codable {
    let error: String
}

struct TasksResponse: Codable {
    let tasks: [TaskModel]
    let count: Int
}

struct ReminderModel: Codable {
    let id: String
    let taskId: String?
    let reminderTime: String
    let message: String
    let sent: Bool?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case reminderTime = "reminder_time"
        case message
        case sent
        case createdAt = "created_at"
    }
}

struct TaskModel: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let userId: String
    let status: String
    let priority: String
    let category: String?
    let dueDate: String?
    let estimatedDuration: Int?
    let isRecurring: Bool?
    let recurringPattern: [String: String]?
    let conversationId: String?
    let createdAt: String?
    let updatedAt: String?
    let reminders: [ReminderModel]?
    let suggestions: [Suggestion]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case userId = "user_id"
        case status
        case priority
        case category
        case dueDate = "due_date"
        case estimatedDuration = "estimated_duration"
        case isRecurring = "is_recurring"
        case recurringPattern = "recurring_pattern"
        case conversationId = "conversation_id"
        case suggestions
        case createdAt = "created_at"
        case reminders
        case updatedAt = "updated_at"
    }
}

struct ApproveResponse: Codable {
    let message: String
    let approvedTasks: [ApprovedTask]?

    enum CodingKeys: String, CodingKey {
        case message
        case approvedTasks = "approved_tasks"
    }
}

struct ApprovedTask: Codable {
    let id: String
    let title: String?
    let notificationSent: Bool?
    let remindersScheduled: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case notificationSent = "notification_sent"
        case remindersScheduled = "reminders_scheduled"
    }
}

struct CreateTasksResponse: Codable {
    let tasks: [CreatedTask]
    let count: Int
    let processingTime: Double?

    enum CodingKeys: String, CodingKey {
        case tasks = "created_tasks"
        case count
        case processingTime = "processing_time"
    }
}

struct CreatedTask: Codable {
    let id: String
    let title: String
}

// MARK: - Subscription Management
extension BraindumpsterAPI {
    func syncSubscriptionStatus(data: [String: Any]) async throws -> [String: Any] {
        let endpoint = "\(baseURL)/subscriptions/sync-status"

        // Get Firebase auth token
        let authToken = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Set request body
        request.httpBody = try JSONSerialization.data(withJSONObject: data)

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError("Failed to sync subscription. Server returned: \(errorMessage)")
        }

        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        print("✅ Subscription synced with backend")
        return result
    }

    func getSubscriptionStatus(userId: String) async throws -> [String: Any] {
        let endpoint = "\(baseURL)/subscriptions/status?user_id=\(userId)"

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return result
    }

    // MARK: - Subscription Management (In-App)

    /// Get subscription status for current authenticated user
    func getSubscriptionStatus() async throws -> [String: Any] {
        guard let userId = AuthService.shared.user?.uid else {
            throw APIError.unauthorized
        }

        let endpoint = "\(baseURL)/subscriptions/status?user_id=\(userId)"

        // Get auth token
        let token = try await AuthService.shared.getIdToken()

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return result
    }

    /// Cancel user's subscription
    func cancelSubscription(reason: String = "user_cancelled") async throws -> [String: Any] {
        guard let userId = AuthService.shared.user?.uid else {
            throw APIError.unauthorized
        }

        let endpoint = "\(baseURL)/subscriptions/cancel"

        // Get auth token
        let token = try await AuthService.shared.getIdToken()

        // Create request body
        let requestBody: [String: Any] = [
            "user_id": userId,
            "reason": reason
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return result
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case unauthorized
    case invalidResponse
    case serverError(String)
    case httpError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired 🔐 Sign in again to continue"
        case .invalidResponse:
            return "Got a weird response from the server 🤔 Try again?"
        case .serverError(let message):
            // Return friendly version if it's a technical message
            if message.lowercased().contains("internal") || message.lowercased().contains("500") {
                return "Our servers hiccuped 😅 Give it another shot"
            }
            return message
        case .httpError(let code):
            switch code {
            case 400:
                return "Something's not quite right with that request 🤔"
            case 401:
                return "Session expired 🔐 Sign in again to continue"
            case 403:
                return "You don't have permission for that 🚫"
            case 404:
                return "Couldn't find what you're looking for 🔍"
            case 429:
                return "Slow down there, speedy! Try again in a moment ⏱️"
            case 500...599:
                return "Our servers are taking a coffee break ☕ Try again soon"
            default:
                return "Something unexpected happened 😕 Let's try that again"
            }
        case .networkError(let error):
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("internet") || errorString.contains("offline") || errorString.contains("network") {
                return "You're offline 🌐 Check your connection and try again"
            } else if errorString.contains("timeout") {
                return "That's taking too long ⏰ Check your connection?"
            } else {
                return "Can't reach the server 📡 Check your internet?"
            }
        }
    }

    /// User-friendly title for error alerts
    var friendlyTitle: String {
        switch self {
        case .unauthorized:
            return "Session Expired"
        case .invalidResponse, .serverError:
            return "Oops!"
        case .httpError(let code) where code >= 500:
            return "Server Issues"
        case .httpError:
            return "Something's Wrong"
        case .networkError:
            return "Connection Problem"
        }
    }
}

// MARK: - Timezone Management
extension BraindumpsterAPI {
    /// Update user's timezone information in backend
    /// Matches backend endpoint: PUT /api/auth/profile/{user_id}/timezone
    func updateUserTimezone(timezoneInfo: [String: Any]) async throws {
        // Get user ID first
        guard let userId = AuthService.shared.user?.uid else {
            throw APIError.unauthorized
        }

        // Extract timezone identifier from timezoneInfo
        guard let timezone = timezoneInfo["userTimezone"] as? String else {
            throw APIError.serverError("Timezone identifier is required")
        }

        let endpoint = "\(baseURL)/auth/profile/\(userId)/timezone"

        // Get Firebase auth token
        let token = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            AuthService.shared.getIdToken { result in
                continuation.resume(with: result)
            }
        }

        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Backend expects: {"timezone": "Europe/Brussels"}
        let body: [String: Any] = ["timezone": timezone]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        print("✅ Timezone updated successfully in backend: \(timezone)")
    }
}
