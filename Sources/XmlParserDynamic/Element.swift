//
//  Element.swift
//  
//
//  Created by COFFEE on 2020/12/16.
//

import Foundation

/// Element.
public struct Element: Equatable {
    
    // TODO: internal
    public init(character: String, xPath: String) {
        self.character = character
        self.xPath = xPath
    }
    
    /// Element's character.
    public let character: String
    
    /// Element's XPath.
    public let xPath: String
}
