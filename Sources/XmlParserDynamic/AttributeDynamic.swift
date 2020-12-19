//
//  AttributeDynamic.swift
//  
//
//  Created by COFFEE on 2020/12/15.
//

import Foundation

@dynamicMemberLookup
/// Attributes That can get dynamically.
public struct AttributeDynamic {
    let dict: [String: [String : String]]
    let xPath: XPath
    public subscript(key key: String) -> Self {
        self[dynamicMember: key]
    }
    
    public subscript(index: Int) -> Self {
        .init(dict: dict, xPath: xPath[index])
    }
    
    public subscript(dynamicMember member: String) -> Self {
        .init(dict: dict, xPath: xPath[key: member])
    }
    
    private init(dict:[String: [String : String]], xPath: XPath) {
        self.dict = dict
        self.xPath = xPath
    }
    
    public init(dict:[String: [String : String]]) {
        self.dict = dict
        self.xPath = XPath()
    }
    
    /// Get attributes from dynamically path.
    /// - Returns: Attributes.
    public func getAttributes() -> [String: [String : String]] {
        return getAttributes(for: xPath.get())
    }
    
    /// Get attributes from xPath.
    /// - Parameter xPath: xPath
    /// - Returns: Attributes.
    public func getAttributes(for xPath: String) -> [String: [String : String]] {
        if xPath.isEmpty {
            return dict
        } else {
            return dict.filter { (dictionary) -> Bool in
                let exp = try! NSRegularExpression(pattern: xPath, options: [.ignoreMetacharacters])
                let b = exp.firstMatch(in: dictionary.key, options: [], range: .init(location: 0, length: dictionary.key.count)) != nil
                return b
            }
        }
    }
}
