import Foundation
import Combine

public typealias ParserResultsCallback = (Result<ParserResult,Error>)  -> Void

protocol XMLParserDelegateWrapperDelegate: NSObjectProtocol {
    func xmlParserDelegateWrapper(_ xmlParserDelegateWrapper: XMLParserDelegateWrapper, didCompleteWithResult result: Result<ParserResult, Error>)
}

class XMLParserDelegateWrapper: NSObject, XMLParserDelegate {
    internal init(parser: XMLParser, elements: [Element] = [], dicts: [String : [String : String]] = [:], indexTable: [URL : Int] = [:], currentUrl: URL = URL(string: "https://jo.coe/")!, targetUrl: URL, delegate: XMLParserDelegateWrapperDelegate? = nil) {
        self.parser = parser
        self.elements = elements
        self.dicts = dicts
        self.indexTable = indexTable
        self.currentUrl = currentUrl
        self.targetUrl = targetUrl
        self.delegate = delegate
        super.init()
        parser.delegate = self
    }
    
    
    private let parser: XMLParser
    private var elements:[Element] = []
    private var dicts:[String : [String : String]] = [:]
    private var indexTable: [URL: Int] = [:]
    private var currentUrl = URL(string: "https://jo.coe/")!
    private let targetUrl: URL
    weak var delegate: XMLParserDelegateWrapperDelegate?
    
    func parse() {
        parser.parse()
    }
    
    func abortParsing() {
        parser.abortParsing()
    }
    
    func beOutOfTarget(currentUrl: URL, targetUrl: URL) throws -> Bool {
        guard let targetString = targetUrl.absoluteString.removingPercentEncoding?.replacingOccurrences(of: #"[0-9]+"#, with: String(Int.max)) else {
            fatalError()
        }
        let compare = currentUrl.absoluteString.compare(targetString, options: [.numeric])
        switch compare {
        case .orderedAscending:
            return false
        case .orderedSame:
            return false
        case .orderedDescending:
            return true
        }
    }
    
    private func isTargeting(currentUrl: URL, targetUrl: URL) throws -> Bool {
        guard let targetString = targetUrl.absoluteString.removingPercentEncoding else {
            throw NSError(domain: "aaa", code: 1, userInfo: nil)
        }
        let regularExpression = try NSRegularExpression(pattern: targetString, options: [])
        let text = currentUrl.absoluteString
        return regularExpression.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) != nil
    }
    
    func parserDidStartDocument(_ parser: XMLParser) {
        Swift.print(#line,"parserDidStartDocument")
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        ret(parserResults: .init(elements: elements, attributes: .init(dict: dicts)))
    }
    
    private func ret(parserResults: ParserResult) {
        delegate?.xmlParserDelegateWrapper(self, didCompleteWithResult: .success(parserResults))
    }
    
    private func err(error: Error) {
        delegate?.xmlParserDelegateWrapper(self, didCompleteWithResult: .failure(error))
    }
    
    @objc func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        currentUrl.appendPathComponent(elementName)
        if indexTable[currentUrl] != nil {
            indexTable[currentUrl]! += 1
        } else {
            indexTable[currentUrl] = 1
        }
        currentUrl.appendPathComponent(String(indexTable[currentUrl]!))
        //現在のパスが、前方一致してるんであれば保存
        if isPrefixPath(current: currentUrl.path, target: targetUrl.path) {
            dicts[toXPath(url: currentUrl)!] = attributeDict
        }
        
        // TODO: currentUrlが、もうアクセスする可能性がなくなったらコールバックして解析を打ち切る
        let b = try! beOutOfTarget(currentUrl: currentUrl, targetUrl: targetUrl)
        if b {
            ret(parserResults: .init(elements: elements, attributes: .init(dict: dicts)))
        }
    }
    
    private func isPrefixPath(current:String, target:String) -> Bool {
        let targetSplit = target.replacingOccurrences(of: #"[0-9]+"#, with: String(Int.max)).split(separator: "/")
        let currentSplit = current.split(separator: "/")
        for (offset,element) in currentSplit.enumerated() {
            if targetSplit.count == offset {
                return true
            }
            if offset.isMultiple(of: 2) {
                guard element == targetSplit[offset] else {
                    return false
                }
                
            } else {
                if Int(element)! != Int(targetSplit[offset])! && Int(targetSplit[offset])! != Int.max  {
                    return false
                }
            }
        }
        return true
    }
    
    
    @objc func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentUrl.deleteLastPathComponent()
        currentUrl.deleteLastPathComponent()
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        Swift.print(#line,"foundCharacters:\(string)")
        //pathが一致している間、保存する
        let targeting = try! isTargeting(currentUrl: currentUrl, targetUrl: targetUrl)
        if targeting {
            elements.append(.init(character: string, xPath: toXPath(url: currentUrl)!))
        }
    }
    
    //    func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? {
    //
    //    }
    
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        err(error: parseError)
    }
    
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        err(error: validationError)
    }
}


@available(OSX 10.15, *)
struct ParserSubscription: Subscription {
    let combineIdentifier: CombineIdentifier
    let parser: XMLParser
    
    func request(_ demand: Subscribers.Demand) {
        parser.parse()
    }
    
    func cancel() {
        Swift.print(#line,"cancel")
        parser.abortParsing()
    }
}

public func toXPath(url: URL) -> String? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        return nil
    }
    
    return components.path.split(separator: "/").enumerated().reduce("") { (result, enumerated) -> String in
        if enumerated.offset.isMultiple(of: 2) {
            return result + "/\(enumerated.element)"
        } else {
            if let i = Int(enumerated.element) {
                return result + "[\(i)]"
            } else {
                return result + "[0-9]+"
            }
        }
    }
}
