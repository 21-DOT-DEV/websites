//
//  RedirectEdgeEmulator.swift
//  UtilitiesCLITests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Network

/// A loopback HTTP server that answers probes the way Cloudflare Pages would
/// for a declared set of `_redirects` rules — an independent edge emulator for
/// `util redirects verify` CLI tests (Specs/007).
///
/// The command under test runs as a subprocess, so no in-process stub can
/// answer it: each test binds an ephemeral port on the loopback interface and
/// points `--base-url` at the returned origin. Rules use `_redirects` syntax —
/// `*` splats and `:placeholder`s in the source, `:splat`/`:placeholder`
/// references in the location — and match first-match-wins like the edge, so
/// a wildcard rule's `Location` is expanded exactly the way a deployment
/// expands it. Requests matching no rule get a `404`.
///
/// `NWListener` usage follows Apple's documented contract: handlers install
/// before `start`, the bound port is read only after `.ready`, every response
/// goes out in a single send, and `cancel()` releases the listener (tests
/// never rebind a port, so the asynchronous release needs no wait).
final class RedirectEdgeEmulator: @unchecked Sendable {

    /// One emulated `_redirects` rule.
    struct Rule {
        /// Source pattern — a literal path, `*` splat, or `:placeholder`s.
        let source: String
        /// Status served when `source` matches.
        let status: Int
        /// `Location` value with `:splat`/`:placeholder` references expanded
        /// from the source match; `nil` for non-redirect responses.
        let location: String?
        /// Status served only to `HEAD` probes — used to exercise the
        /// verifier's 405/501 → GET fallback; `nil` serves `status` to all
        /// methods.
        let headStatus: Int?

        init(_ source: String, status: Int, location: String? = nil, headStatus: Int? = nil) {
            self.source = source
            self.status = status
            self.location = location
            self.headStatus = headStatus
        }
    }

    private let queue = DispatchQueue(label: "redirect-edge-emulator")
    private let compiled: [CompiledRule]
    private var listener: NWListener?
    private var readyContinuation: CheckedContinuation<UInt16, Error>?
    private var requests: [(method: String, path: String)] = []

    /// Every request the emulator received, in order — `(method, path)` with
    /// the query stripped and percent-decoding applied, matching what the
    /// matcher saw. Lets a test prove *which* probes the verifier sent —
    /// e.g. that a `GET` retry really followed a refused `HEAD`. Must be read
    /// from off the emulator's queue (a test thread).
    var recordedRequests: [(method: String, path: String)] {
        queue.sync { requests }
    }

    init(rules: [Rule]) {
        self.compiled = rules.map(CompiledRule.init(rule:))
    }

    deinit {
        listener?.cancel()
    }

    /// Binds an ephemeral loopback port and starts serving.
    /// - Returns: The `http://127.0.0.1:<port>` origin for `--base-url`.
    func start() async throws -> URL {
        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = .loopback
        let listener = try NWListener(using: parameters, on: .any)
        listener.newConnectionLimit = 32

        let port = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UInt16, Error>) in
            queue.async {
                self.listener = listener
                self.readyContinuation = continuation
                listener.stateUpdateHandler = { [weak self] state in
                    self?.listenerStateDidChange(state, on: listener)
                }
                listener.newConnectionHandler = { [weak self] connection in
                    self?.handle(connection)
                }
                listener.start(queue: self.queue)
            }
        }

        return URL(string: "http://127.0.0.1:\(port)")!
    }

    /// Cancels the listener — synchronous and safe to call from `defer`.
    /// Must be called from off the emulator's queue (a test thread).
    func cancel() {
        queue.sync {
            listener?.cancel()
            listener = nil
        }
    }

    // MARK: - NWListener plumbing (all on `queue`)

    private func listenerStateDidChange(_ state: NWListener.State, on listener: NWListener) {
        switch state {
        case .ready:
            if let port = listener.port, let continuation = readyContinuation {
                readyContinuation = nil
                continuation.resume(returning: port.rawValue)
            }
        case .failed(let error):
            readyContinuation?.resume(throwing: error)
            readyContinuation = nil
            self.listener = nil
        case .cancelled:
            self.listener = nil
        default:
            break
        }
    }

    private func handle(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            guard case .ready = state else { return }
            // The handler captures the connection strongly — releasing it
            // here bounds the connection's lifetime to its in-flight work.
            connection.stateUpdateHandler = nil
            self?.receive(connection, into: Data())
        }
        connection.start(queue: queue)
    }

    /// Reads until the request's blank-line terminator — a HEAD/GET probe's
    /// headers fit in a handful of receives.
    private func receive(_ connection: NWConnection, into buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] content, _, isComplete, error in
            guard let self else { return }
            var request = buffer
            if let content { request.append(content) }
            let headersComplete = String(data: request, encoding: .utf8)?.contains("\r\n\r\n") ?? false
            if headersComplete || isComplete || error != nil || request.count > 16384 {
                respond(on: connection, to: request)
            } else {
                receive(connection, into: request)
            }
        }
    }

    // MARK: - Edge behavior

    /// Answers one request: parse the request line, run the first matching
    /// rule, and send the response in a single write.
    private func respond(on connection: NWConnection, to request: Data) {
        guard let raw = String(data: request, encoding: .utf8),
              let line = raw.components(separatedBy: "\r\n").first,
              let (method, rawPath) = Self.parseRequestLine(line) else {
            send(on: connection, status: 400)
            return
        }
        let queryless = rawPath.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? rawPath
        let path = queryless.removingPercentEncoding ?? queryless
        requests.append((method, path))

        guard let (rule, match) = firstMatch(for: path) else {
            send(on: connection, status: 404)
            return
        }
        if method == "HEAD", let headStatus = rule.rule.headStatus {
            send(on: connection, status: headStatus)
        } else {
            send(on: connection, status: rule.rule.status,
                 location: rule.rule.location.map { expand($0, with: match) })
        }
    }

    private func send(on connection: NWConnection, status: Int, location: String? = nil) {
        var response = "HTTP/1.1 \(status) \(Self.reasonPhrase(for: status))\r\n"
        if let location { response += "Location: \(location)\r\n" }
        response += "Content-Length: 0\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    /// `METHOD SP request-target SP HTTP-version` — the request-target is an
    /// origin-form path for URLSession probes.
    private static func parseRequestLine(_ line: String) -> (method: String, path: String)? {
        let parts = line.split(separator: " ", maxSplits: 2)
        guard parts.count >= 2 else { return nil }
        return (String(parts[0]), String(parts[1]))
    }

    private static func reasonPhrase(for status: Int) -> String {
        switch status {
        case 200: return "OK"
        case 301: return "Moved Permanently"
        case 302: return "Found"
        case 303: return "See Other"
        case 307: return "Temporary Redirect"
        case 308: return "Permanent Redirect"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 500: return "Internal Server Error"
        case 501: return "Not Implemented"
        default: return "Status"
        }
    }

    // MARK: - Rule matching (independent of UtilLib's RedirectMatcher)

    private struct CompiledRule {
        let rule: Rule
        let regex: NSRegularExpression
        /// Capture-group index → wildcard name (`*` compiles to "splat").
        let groupNames: [Int: String]

        init(rule: Rule) {
            self.rule = rule
            var pattern = "\\A"
            var group = 0
            var names: [Int: String] = [:]

            var index = rule.source.startIndex
            while index < rule.source.endIndex {
                let character = rule.source[index]
                if character == "*" {
                    group += 1
                    names[group] = "splat"
                    pattern += "(.*)"
                    index = rule.source.index(after: index)
                } else if character == ":",
                          let nameStart = rule.source.index(index, offsetBy: 1, limitedBy: rule.source.endIndex),
                          nameStart < rule.source.endIndex,
                          RedirectEdgeEmulator.isPlaceholderStart(rule.source[nameStart]) {
                    var nameEnd = nameStart
                    while nameEnd < rule.source.endIndex,
                          RedirectEdgeEmulator.isPlaceholderCharacter(rule.source[nameEnd]) {
                        nameEnd = rule.source.index(after: nameEnd)
                    }
                    group += 1
                    names[group] = String(rule.source[nameStart..<nameEnd])
                    pattern += "([^/]+)"
                    index = nameEnd
                } else {
                    pattern += NSRegularExpression.escapedPattern(for: String(character))
                    index = rule.source.index(after: index)
                }
            }
            pattern += "\\z"

            self.regex = (try? NSRegularExpression(pattern: pattern))
                ?? (try! NSRegularExpression(pattern: "\\A\\B\\z"))  // matches nothing
            self.groupNames = names
        }

        /// Captured wildcard values when `path` matches the source, else nil.
        /// Groups are read in order so a duplicated placeholder name resolves
        /// last-wins deterministically, the same as `UtilLib`'s compiler.
        func match(_ path: String) -> [String: String]? {
            let range = NSRange(path.startIndex..., in: path)
            guard let result = regex.firstMatch(in: path, range: range) else { return nil }
            var captures: [String: String] = [:]
            for group in 1..<result.numberOfRanges {
                guard let name = groupNames[group],
                      let capture = Range(result.range(at: group), in: path) else { continue }
                captures[name] = String(path[capture])
            }
            return captures
        }
    }

    private func firstMatch(for path: String) -> (rule: CompiledRule, match: [String: String])? {
        for rule in compiled {
            if let match = rule.match(path) { return (rule, match) }
        }
        return nil
    }

    /// Substitutes `:splat`/`:placeholder` references in a location template.
    private func expand(_ template: String, with match: [String: String]) -> String {
        var result = ""
        var index = template.startIndex
        while index < template.endIndex {
            let character = template[index]
            if character == ":",
               let nameStart = template.index(index, offsetBy: 1, limitedBy: template.endIndex),
               nameStart < template.endIndex,
               Self.isPlaceholderStart(template[nameStart]) {
                var nameEnd = nameStart
                while nameEnd < template.endIndex, Self.isPlaceholderCharacter(template[nameEnd]) {
                    nameEnd = template.index(after: nameEnd)
                }
                result += match[String(template[nameStart..<nameEnd])] ?? ""
                index = nameEnd
            } else {
                result.append(character)
                index = template.index(after: index)
            }
        }
        return result
    }

    /// Whether a character can start a placeholder name (`:[A-Za-z]…`).
    private static func isPlaceholderStart(_ character: Character) -> Bool {
        character.isASCII && character.isLetter
    }

    /// Whether a character can continue a placeholder name (`\w`).
    private static func isPlaceholderCharacter(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber || character == "_")
    }
}
