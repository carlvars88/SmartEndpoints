//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public final class DictionaryEncoder {
    private let encoder = JSONEncoder()
    public func encode<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try encoder.encode(value)
        return (try JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }
}
