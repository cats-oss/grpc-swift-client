// The monitoring code below is derived from grpc-swift project.
// https://github.com/grpc/grpc-swift
// BEGIN grpc-swift derivation

#if os(iOS)
import CoreTelephony
#endif
import Dispatch
import Foundation
import SystemConfiguration

@objc protocol RadioAccessTechnologyObserverProtocol {
    #if os(iOS)
    func radioAccessDidChange(_ notification: Notification)
    #endif
}

protocol RadioAccessTechnologyNotificationProtocol {
    func addObserver(_ observer: RadioAccessTechnologyObserverProtocol)
    func removeObserver(_ observer: Any)
}

#if os(iOS)
extension NotificationCenter: RadioAccessTechnologyNotificationProtocol {
    func addObserver(_ observer: RadioAccessTechnologyObserverProtocol) {
        addObserver(
            observer,
            selector: #selector(RadioAccessTechnologyObserverProtocol.radioAccessDidChange(_:)),
            name: .CTRadioAccessTechnologyDidChange,
            object: nil
        )
    }
}

#else
private struct RadioAccessTechnologyMock: RadioAccessTechnologyNotificationProtocol {
    func addObserver(_ observer: RadioAccessTechnologyObserverProtocol) {}
    func removeObserver(_ observer: Any) {}
}
#endif

/// This class may be used to monitor changes on the device that can cause gRPC to silently disconnect (making
/// it seem like active calls/connections are hanging), then manually shut down / restart gRPC channels as
/// needed. The root cause of these problems is that the backing gRPC-Core doesn't get the optimizations
/// made by iOS' networking stack when changes occur on the device such as switching from wifi to cellular,
/// switching between 3G and LTE, enabling/disabling airplane mode, etc.
/// Read more: https://github.com/grpc/grpc-swift/tree/master/README.md#known-issues
/// Original issue: https://github.com/grpc/grpc-swift/issues/337
public final class NetworkMonitor: RadioAccessTechnologyObserverProtocol {
    public static let queueName = "GRPCClient.NetworkMonitor.queue"
    private let queue: DispatchQueue
    private let reachability: SCNetworkReachability

    #if os(iOS)
    private let notification: RadioAccessTechnologyNotificationProtocol
    /// Instance of network info being used for obtaining cellular technology names.
    public let cellularInfo = CTTelephonyNetworkInfo()
    /// Name of the cellular technology being used (e.g., `CTRadioAccessTechnologyLTE`).
    public private(set) var cellularName: String?
    /// Whether the device is currently using wifi (versus cellular).
    public private(set) var isUsingWifi: Bool
    #endif
    /// Whether the network is currently reachable. Backed by `SCNetworkReachability`.
    public private(set) var isReachable: Bool
    /// Network state handler.
    public var stateHandler: ((State) -> Void)?

    /// Represents a state of connectivity.
    public struct State: Equatable {
        /// The most recent change that was made to the state.
        public var lastChange: Change
        /// Whether this state is currently reachable/online.
        public var isReachable: Bool

        public init(change: Change, isReachable: Bool) {
            self.lastChange = change
            self.isReachable = isReachable
        }
    }

    /// A change in network condition.
    public enum Change: Equatable {
        /// The device switched from offline to wifi.
        case offlineToWifi
        /// The device switched from wifi to offline.
        case wifiToOffline
        #if os(iOS)
        /// The device switched from offline to cellular.
        case offlineToCellular
        /// The device switched from cellular to offline.
        case cellularToOffline
        /// The device switched from cellular to wifi.
        case cellularToWifi
        /// The device switched from wifi to cellular.
        case wifiToCellular
        /// The cellular technology changed (e.g., 3G <> LTE).
        case cellularTechnology(technology: String)
        #endif
    }

    #if os(iOS)
    public convenience init?(
        host: String = "google.com",
        queue: DispatchQueue = DispatchQueue(label: NetworkMonitor.queueName),
        handler: ((State) -> Void)? = nil
    ) {
        self.init(host: host, queue: queue, notification: NotificationCenter.default, handler: handler)
    }
    #else
    public convenience init?(
        host: String = "google.com",
        queue: DispatchQueue = DispatchQueue(label: NetworkMonitor.queueName),
        handler: ((State) -> Void)? = nil
    ) {
        self.init(host: host, queue: queue, notification: RadioAccessTechnologyMock(), handler: handler)
    }
    #endif

    init?(
        host: String,
        queue: DispatchQueue,
        notification: RadioAccessTechnologyNotificationProtocol,
        handler: ((State) -> Void)? = nil
        ) {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else {
            return nil
        }

        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)
        let isReachable = flags.contains(.reachable)
        self.isReachable = isReachable
        self.queue = queue
        self.stateHandler = handler
        self.reachability = reachability

        #if os(iOS)
        self.notification = notification
        self.isUsingWifi = !flags.contains(.isWWAN) && isReachable
        self.cellularName = cellularInfo.currentRadioAccessTechnology
        notification.addObserver(self)
        #endif
        startMonitoringReachability()
    }

    deinit {
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(),
                                                   CFRunLoopMode.commonModes.rawValue)
        #if os(iOS)
        notification.removeObserver(self)
        #endif
    }

    #if os(iOS)
    // MARK: - Cellular
    @objc public func radioAccessDidChange(_ notification: Notification) {
        queue.async {
            let cellularName = notification.object as? String ?? self.cellularInfo.currentRadioAccessTechnology
            let notifyForCellular = self.cellularName != cellularName && self.isReachable && !self.isUsingWifi
            self.cellularName = cellularName

            if notifyForCellular, let cellularName = cellularName {
                self.stateHandler?(State(
                    change: .cellularTechnology(technology: cellularName),
                    isReachable: self.isReachable
                ))
            }
        }
    }
    #endif

    // MARK: - Reachability
    private func startMonitoringReachability() {
        let info = Unmanaged.passUnretained(self).toOpaque()
        var context = SCNetworkReachabilityContext(version: 0, info: info, retain: nil,
                                                   release: nil, copyDescription: nil)
        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            let observer = info.map { Unmanaged<NetworkMonitor>.fromOpaque($0).takeUnretainedValue() }
            observer?.reachabilityDidChange(with: flags)
        }

        SCNetworkReachabilitySetCallback(reachability, callback, &context)
        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(),
                                                 CFRunLoopMode.commonModes.rawValue)
    }

    private func reachabilityDidChange(with flags: SCNetworkReachabilityFlags) {
        queue.async {
            let isReachable = flags.contains(.reachable)
            #if os(iOS)
            let isUsingWifi = !flags.contains(.isWWAN) && isReachable
            #endif

            let changeState: Change?
            #if os(iOS)
            switch (self.isReachable, isReachable, self.isUsingWifi, isUsingWifi) {
            case (true, true, true, false):
                changeState = .wifiToCellular

            case (true, true, false, true):
                changeState = .cellularToWifi

            case (true, false, true, _):
                changeState = .wifiToOffline

            case (true, false, false, _):
                changeState = .cellularToOffline

            case (false, true, _, true):
                changeState = .offlineToWifi

            case (false, true, _, false):
                changeState = .offlineToCellular

            case (true, true, true, true),
                 (true, true, false, false),
                 (false, false, _, _):
                changeState = nil
            }
            #else
            switch (self.isReachable, isReachable) {
            case (true, false):
                changeState = .wifiToOffline

            case (false, true):
                changeState = .offlineToWifi

            case (false, false),
                 (true, true):
                changeState = nil
            }
            #endif

            #if os(iOS)
            self.isUsingWifi = isUsingWifi
            #endif
            self.isReachable = isReachable
            if let changeState = changeState {
                self.stateHandler?(State(change: changeState, isReachable: isReachable))
            }
        }
    }
}
