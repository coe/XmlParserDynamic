//
//  XmlDynamicParser.swift
//
//
//  Created by COFFEE on 2020/12/12.
//

import Foundation

enum XmlDynamicParserError: Error {
    case `default`
}

private protocol InitializableObject {}
extension Data: InitializableObject {}
extension InputStream: InitializableObject {}
extension URL: InitializableObject {}

@dynamicMemberLookup
/// A xml parser.
/// This parser can have path by the dynamic member like a XPath.
public class XmlParserDynamic: NSObject {
    /// Initializes a parser with xml data.
    /// - Parameter data: xml data.
    public convenience init(data: Data) {
        self.init(initializableObject: data)
    }
    
    /// Initializes a parser with xml stream.
    /// - Parameter stream: xml stream.
    public convenience init(stream: InputStream) {
        self.init(initializableObject: stream)
    }
    
    /// Initializes a parser with url.
    /// - Parameter url: xml URL.
    public convenience init(url: URL) {
        self.init(initializableObject: url)
    }
    
    private let initializableObject: InitializableObject
    private var xPath: XPath
    
    private init(initializableObject: InitializableObject) {
        self.initializableObject = initializableObject
        self.xPath = XPath()
    }
    
    private init(initializableObject: InitializableObject, path: XPath) {
        self.initializableObject = initializableObject
        self.xPath = path
    }
    
    public subscript(dynamicMember member: String) -> XmlParserDynamic {
        xPath = xPath[key: member]
        return self
    }
    
    public subscript(key key: String) -> XmlParserDynamic {
        self[dynamicMember: key]
    }
    
    public subscript(index: Int) -> XmlParserDynamic {
        xPath = xPath[index]
        return self
    }
    
    /// Get xml elements. Elements is from the dynamic path.
    /// - Parameter callback: Elements or Error.
    public func getElements(callback: @escaping ParserResultsCallback) {
        do {
            let (xmlParser, url) = try prepareParser()
            self.callback = callback
            self.parserWrapper = XMLParserDelegateWrapper(parser: xmlParser, targetUrl: url)
            parserWrapper?.delegate = self
            parserWrapper?.parse()
        } catch {
            callback(.failure(error))
        }
    }
    
    private func prepareParser() throws -> (xmlParser: XMLParser, url: URL) {
        let xmlParser: XMLParser?
        switch initializableObject {
        case let data as Data: xmlParser = XMLParser(data: data)
        case let url as URL: xmlParser = XMLParser(contentsOf: url)
        case let stream as InputStream: xmlParser = XMLParser(stream: stream)
        default: xmlParser = nil
        }
        guard let myXmlParser = xmlParser else {
            throw NSError(domain: "d", code: 1, userInfo: nil)
        }

        let regex = try! NSRegularExpression(pattern: #"\[([0-9]+)\]"#, options: [])
        let target = xPath.get().split(separator: "/").reduce("") { (result, string) -> String in
            guard let _ = regex.firstMatch(in: String(string), options: [], range: .init(string.range(of: string)!, in: string)) else {
                return result + "/" + string + "/" + #"[0-9]+"#
            }
            return result + "/" + regex.stringByReplacingMatches(in: String(string), options: [], range: .init(string.range(of: string)!, in: string), withTemplate: "/$1")
        }
        var c = URLComponents(url: URL(string: "https://jo.coe/")!, resolvingAgainstBaseURL: false)
        c?.path = target
        return (myXmlParser, c!.url!)
    }

    private var parserWrapper: XMLParserDelegateWrapper?
    private var callback: ParserResultsCallback?
}

extension XmlParserDynamic: XMLParserDelegateWrapperDelegate {
    func xmlParserDelegateWrapper(_ xmlParserDelegateWrapper: XMLParserDelegateWrapper, didCompleteWithResult result: Result<ParserResult, Error>) {
        callback?(result)
        callback = nil
        parserWrapper = nil
    }
}

#if canImport(Combine)
import Combine

extension XmlParserDynamic {
    /// Get the publisher for xml elements. Elements is from the dynamic path.
    /// - Returns: Elements publisher.
    @available(OSX 10.15, *)
    public func getElementsPublisher() -> AnyPublisher<ParserResult, Error> {
        do {
            let (xmlParser, url) = try prepareParser()
            let parser = Parser(parser: xmlParser, targetUrl: url)
            return parser.publisher
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}
#endif
