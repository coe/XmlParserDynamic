//
//  ParserResults.swift
//  
//
//  Created by COFFEE on 2020/12/15.
//

import Foundation

/// Result that parsed xml.
public struct ParserResult {
    /// Elements parsed xml.
    public let elements:[Element]
    /// Attributes related to the elements.
    public let attributes:AttributeDynamic
}
