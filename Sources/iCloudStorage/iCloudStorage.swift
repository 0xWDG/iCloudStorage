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

    /// The cancellables to store.
    var cancellables = Set<AnyCancellable>()

    /// The observed storage
    @ObservedObject private var store: Storage

    /// Creates an `iCloudStorage` property.
    ///
    /// - Parameter wrappedValue: The default value.
    /// - Parameter key: The key to read and write to.
    public init(wrappedValue: T, _ key: String) {
        self.key = key
        self.defaultValue = wrappedValue
        self.store = Storage(
            NSUbiquitousKeyValueStore.default.object(forKey: key) as? T ?? defaultValue
        )

        // Set-up notification for changed key.
        NotificationCenter.default.publisher(
            for: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        .receive(on: DispatchQueue.main)
        .sink { [self] notification in
            if let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
               keys.contains(key) {
                self.store.value = NSUbiquitousKeyValueStore.default.object(forKey: key) as? T ?? defaultValue
            }
        }
        .store(in: &cancellables)
    }

    /// The value of the key in iCloud.
    public var wrappedValue: T {
        get {
            return store.value
        }

        nonmutating set {
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: key)
            store.value = newValue
        }
    }

    /// A binding to the value of the key in iCloud.
    public var projectedValue: Binding<T> {
        $store.value
    }

    // MARK: - Storage
    private final class Storage: ObservableObject {
        var parentWillChange: ObservableObjectPublisher?

        var value: T {
            willSet {
                objectWillChange.send()
                parentWillChange?.send()
            }
        }

        init(_ value: T) {
            self.value = value
        }
    }

    // MARK: - Get parent
    /// Get the parent, to send a willChange event to there.
    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance instance: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> T {
        get {
            instance[keyPath: storageKeyPath].store.parentWillChange = (
                instance.objectWillChange as? ObservableObjectPublisher
            )

            return instance[keyPath: storageKeyPath].wrappedValue
        }
        set {
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}
#endif
