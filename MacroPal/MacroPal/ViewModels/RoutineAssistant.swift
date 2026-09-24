//
//  RoutineAssistant.swift
//  MacroPal
//

import Foundation
import FoundationModels
import OSLog

private let log = Logger(subsystem: "com.francislozano.MacroPal", category: "RoutineAssistant")

/// Reads a routine described in words with Apple's on-device model — no key, no server. Each
/// message is read on its own, so there's no conversation to keep.
enum RoutineAssistant {
    /// False without Apple Intelligence (device not eligible, turned off, or the model still
    /// downloading); the Edit Routine form works without it.
    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    // A first draft ("You turn a short description … into settings") was refused as "may
    // contain sensitive content" for every message; this wording isn't.
    private static let instructions = """
        The user describes how often they go to the gym. Fill in the fields from their words \
        only; leave out anything they don't say.
        """

    static func interpret(_ message: String) async throws -> RoutineRequest {
        let session = LanguageModelSession(instructions: instructions)
        do {
            let request = try await session.respond(
                to: message,
                generating: RoutineRequest.self,
                options: GenerationOptions(sampling: .greedy)
            ).content
            log.info("Read \"\(message, privacy: .private)\" as \(String(describing: request), privacy: .private)")
            return request
        } catch {
            log.error("Reading a routine failed: \(String(describing: error), privacy: .public)")
            throw error
        }
    }
}
