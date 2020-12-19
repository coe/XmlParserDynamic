//
//  XPath.swift
//  
//
//  Created by COFFEE on 2020/12/13.
//

import Foundation

@dynamicMemberLookup
struct XPath {
    private init(path: URL) {
        self.path = path
    }
    
    public init() {
        self.path = URL(string: "xpath://example.com/")!
    }
    
    private let path: URL
    public subscript(dynamicMember member: String) -> Self {
        XPath(path: path.appendingPathComponent(member))
    }
    
    public subscript(key key: String) -> Self {
        self[dynamicMember: key]
    }
    
    public subscript(index: Int) -> Self {
        let lastPath = path.pathComponents.last!
        
        return XPath(path: path.deletingLastPathComponent()
                        .appendingPathComponent(String(format: "%@[%zd]", lastPath, index + 1)))
    }
    
    public func get() -> String {
        path.path
    }
}
