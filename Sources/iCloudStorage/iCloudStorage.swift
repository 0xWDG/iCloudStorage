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

    @State private var value: T

    /// Creates an `iCloudStorage` property.
    ///
    /// - Parameter wrappedValue: The default value.
    /// - Parameter key: The key to read and write to.
    public init(wrappedValue: T, _ key: String) {
        self.key = key
        self.defaultValue = wrappedValue
        self.value = NSUbiquitousKeyValueStore.default.object(forKey: key) as? T ?? defaultValue
    }

    /// The value of the key in iCloud.
    public var wrappedValue: T {
        get {
            return value
        }

        nonmutating set {
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: key)
            value = newValue
        }
    }

    /// A binding to the value of the key in iCloud.
    public var projectedValue: Binding<T> {
        Binding {
            return self.wrappedValue
        } set: { newValue in
            self.wrappedValue = newValue
        }
    }
}
#endif
