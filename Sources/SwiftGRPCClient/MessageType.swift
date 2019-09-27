public enum MessageType {
    case data, close
    case send(shouldReconnect: Bool)
    case receive(shouldReconnect: Bool)

    var isSending: Bool {
        guard case .send = self else { return false }
        return true
    }

    var isReceiveing: Bool {
        guard case .receive = self else { return false }
        return true
    }

    var isReconnectable: Bool {
        switch self {
        case .data, .close:
            return false

        case .send(let shouldReconnect), .receive(let shouldReconnect):
            return shouldReconnect
        }
    }
}
