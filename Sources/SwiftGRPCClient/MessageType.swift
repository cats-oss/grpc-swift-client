public enum MessageType {
    case data, close
    case send(shouldRetry: Bool)
    case receive(shouldRetry: Bool)

    var isSending: Bool {
        guard case .send = self else { return false }
        return true
    }

    var isReceiveing: Bool {
        guard case .receive = self else { return false }
        return true
    }

    var isRetryable: Bool {
        switch self {
        case .data, .close:
            return false

        case .send(let shouldRetry), .receive(let shouldRetry):
            return shouldRetry
        }
    }
}
