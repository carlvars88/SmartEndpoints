//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public enum APIError: Error { case http(status: Int, payload: String?), invalidURL }
