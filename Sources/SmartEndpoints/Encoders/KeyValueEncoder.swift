//
//  KeyValueEncoder.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct KeyValuePair: Equatable, Sendable {
    public let key: String
    public let value: String
}

/// Encodes a flat `Encodable` value into an ordered list of `KeyValuePair`s,
/// suitable for use in URL query strings and `application/x-www-form-urlencoded` bodies.
///
/// - `nil` optionals are skipped — never emitted as `"<null>"`.
/// - Arrays produce repeated keys: `[1, 2, 3]` → `ids=1&ids=2&ids=3`.
/// - Nested types use dot-separated keys: `address.city=Paris`.
public struct KeyValueEncoder {
    public init() {}

    public func encode<T: Encodable>(_ value: T) throws -> [KeyValuePair] {
        let impl = Impl(codingPath: [])
        try value.encode(to: impl)
        return impl.storage.pairs
    }
}

// MARK: - Private implementation

private extension KeyValueEncoder {

    final class Storage {
        var pairs: [KeyValuePair] = []
    }

    final class Impl: Encoder {
        let codingPath: [any CodingKey]
        let userInfo: [CodingUserInfoKey: Any] = [:]
        let storage: Storage

        init(codingPath: [any CodingKey], storage: Storage = .init()) {
            self.codingPath = codingPath
            self.storage = storage
        }

        func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
            KeyedEncodingContainer(KeyedContainer<Key>(storage: storage, codingPath: codingPath))
        }

        func unkeyedContainer() -> any UnkeyedEncodingContainer {
            let key = codingPath.map(\.stringValue).joined(separator: ".")
            return UnkeyedContainer(storage: storage, codingPath: codingPath, key: key)
        }

        func singleValueContainer() -> any SingleValueEncodingContainer {
            SingleValueContainer(storage: storage, codingPath: codingPath)
        }
    }

    // MARK: Keyed

    struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let storage: Storage
        let codingPath: [any CodingKey]

        private func flatKey(for key: Key) -> String {
            let parent = codingPath.map(\.stringValue).joined(separator: ".")
            return parent.isEmpty ? key.stringValue : "\(parent).\(key.stringValue)"
        }

        private mutating func append(_ value: String, for key: Key) {
            storage.pairs.append(KeyValuePair(key: flatKey(for: key), value: value))
        }

        mutating func encodeNil(forKey key: Key)                    throws { /* skip */ }
        mutating func encode(_ value: Bool,   forKey key: Key)      throws { append(value ? "true" : "false", for: key) }
        mutating func encode(_ value: String, forKey key: Key)      throws { append(value, for: key) }
        mutating func encode(_ value: Double, forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: Float,  forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: Int,    forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: Int8,   forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: Int16,  forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: Int32,  forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: Int64,  forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: UInt,   forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: UInt8,  forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: UInt16, forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: UInt32, forKey key: Key)      throws { append("\(value)", for: key) }
        mutating func encode(_ value: UInt64, forKey key: Key)      throws { append("\(value)", for: key) }

        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            let nested = Impl(codingPath: codingPath + [key], storage: storage)
            try value.encode(to: nested)
        }

        mutating func nestedContainer<NK: CodingKey>(keyedBy type: NK.Type, forKey key: Key) -> KeyedEncodingContainer<NK> {
            KeyedEncodingContainer(KeyedContainer<NK>(storage: storage, codingPath: codingPath + [key]))
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
            UnkeyedContainer(storage: storage, codingPath: codingPath + [key], key: flatKey(for: key))
        }

        mutating func superEncoder()            -> any Encoder { Impl(codingPath: codingPath, storage: storage) }
        mutating func superEncoder(forKey key: Key) -> any Encoder { Impl(codingPath: codingPath + [key], storage: storage) }
    }

    // MARK: Unkeyed (arrays → repeated keys)

    struct UnkeyedContainer: UnkeyedEncodingContainer {
        let storage: Storage
        let codingPath: [any CodingKey]
        let key: String
        var count: Int = 0

        private mutating func append(_ value: String) {
            storage.pairs.append(KeyValuePair(key: key, value: value))
            count += 1
        }

        mutating func encodeNil()               throws { count += 1 /* skip */ }
        mutating func encode(_ value: Bool)     throws { append(value ? "true" : "false") }
        mutating func encode(_ value: String)   throws { append(value) }
        mutating func encode(_ value: Double)   throws { append("\(value)") }
        mutating func encode(_ value: Float)    throws { append("\(value)") }
        mutating func encode(_ value: Int)      throws { append("\(value)") }
        mutating func encode(_ value: Int8)     throws { append("\(value)") }
        mutating func encode(_ value: Int16)    throws { append("\(value)") }
        mutating func encode(_ value: Int32)    throws { append("\(value)") }
        mutating func encode(_ value: Int64)    throws { append("\(value)") }
        mutating func encode(_ value: UInt)     throws { append("\(value)") }
        mutating func encode(_ value: UInt8)    throws { append("\(value)") }
        mutating func encode(_ value: UInt16)   throws { append("\(value)") }
        mutating func encode(_ value: UInt32)   throws { append("\(value)") }
        mutating func encode(_ value: UInt64)   throws { append("\(value)") }

        mutating func encode<T: Encodable>(_ value: T) throws {
            let nested = Impl(codingPath: codingPath, storage: storage)
            try value.encode(to: nested)
            count += 1
        }

        mutating func nestedContainer<NK: CodingKey>(keyedBy type: NK.Type) -> KeyedEncodingContainer<NK> {
            KeyedEncodingContainer(KeyedContainer<NK>(storage: storage, codingPath: codingPath))
        }

        mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
            UnkeyedContainer(storage: storage, codingPath: codingPath, key: key)
        }

        mutating func superEncoder() -> any Encoder { Impl(codingPath: codingPath, storage: storage) }
    }

    // MARK: Single value (used by Optional, RawRepresentable, etc.)

    struct SingleValueContainer: SingleValueEncodingContainer {
        let storage: Storage
        let codingPath: [any CodingKey]

        private var key: String { codingPath.map(\.stringValue).joined(separator: ".") }

        private mutating func append(_ value: String) {
            storage.pairs.append(KeyValuePair(key: key, value: value))
        }

        mutating func encodeNil()               throws { /* skip */ }
        mutating func encode(_ value: Bool)     throws { append(value ? "true" : "false") }
        mutating func encode(_ value: String)   throws { append(value) }
        mutating func encode(_ value: Double)   throws { append("\(value)") }
        mutating func encode(_ value: Float)    throws { append("\(value)") }
        mutating func encode(_ value: Int)      throws { append("\(value)") }
        mutating func encode(_ value: Int8)     throws { append("\(value)") }
        mutating func encode(_ value: Int16)    throws { append("\(value)") }
        mutating func encode(_ value: Int32)    throws { append("\(value)") }
        mutating func encode(_ value: Int64)    throws { append("\(value)") }
        mutating func encode(_ value: UInt)     throws { append("\(value)") }
        mutating func encode(_ value: UInt8)    throws { append("\(value)") }
        mutating func encode(_ value: UInt16)   throws { append("\(value)") }
        mutating func encode(_ value: UInt32)   throws { append("\(value)") }
        mutating func encode(_ value: UInt64)   throws { append("\(value)") }

        mutating func encode<T: Encodable>(_ value: T) throws {
            let nested = Impl(codingPath: codingPath, storage: storage)
            try value.encode(to: nested)
        }
    }
}
