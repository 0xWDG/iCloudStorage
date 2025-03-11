//
//  iCloudStorage.swift
//  iCloudStorage
//
//  Created by Wesley de Groot on 2025-01-24.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/iCloudStorage
//  MIT License
//

#if canImport(SwiftUI)
import Foundation
import SwiftUI
import Combine

/// A property wrapper that reads and writes to iCloud.
///
/// Example:
/// ```
/// @iCloudStorage("key") var value: String = "default"
/// ```
@propertyWrapper
public struct iCloudStorage<T>: DynamicProperty {
    // swiftlint:disable:previous type_name
    /// The key to read and write to.
    let key: String

    /// The default value to use if the value is not set yet.
    let defaultValue: T

    var cancellables = Set<AnyCancellable>()

    private final class Storage: ObservableObject {
        var value: T {
            willSet {
                objectWillChange.send()
            }
        }

        init(_ value: T) {
            self.value = value
        }
    }

    @ObservedObject private var value: Storage

    /// Creates an `iCloudStorage` property.
    ///
    /// - Parameter wrappedValue: The default value.
    /// - Parameter key: The key to read and write to.
    public init(wrappedValue: T, _ key: String) {
        self.key = key
        self.defaultValue = wrappedValue
        self.value = Storage(
            NSUbiquitousKeyValueStore.default.object(forKey: key) as? T ?? defaultValue
        )

        NotificationCenter.default.publisher(
            for: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        .receive(on: DispatchQueue.main)
        .sink { [self] notification in
            if let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
               keys.contains(key) {
                self.value.value = NSUbiquitousKeyValueStore.default.object(forKey: key) as? T ?? defaultValue
                self.value.objectWillChange.send()
            }
        }
        .store(in: &cancellables)
    }

    /// The value of the key in iCloud.
    public var wrappedValue: T {
        get {
            return value.value
        }

        nonmutating set {
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: key)
            value.value = newValue
        }
    }

    /// A binding to the value of the key in iCloud.
    public var projectedValue: Binding<T> {
        Binding {
            return self.wrappedValue
        } set: { newValue in
            value.value = newValue
            self.wrappedValue = newValue
        }
    }
}
#endif
