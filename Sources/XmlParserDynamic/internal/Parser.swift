//
//  Parser.swift
//  
//
//  Created by COFFEE on 2020/12/15.
//

import Foundation
#if canImport(Combine)
import Combine

@available(OSX 10.15, *)
class Parser: NSObject {
    private let targetUrl: URL
    private let parser: XMLParser
    private var parserWrapper: XMLParserDelegateWrapper?
    
    init(parser: XMLParser, targetUrl: URL) {
        self.targetUrl = targetUrl
        self.parser = parser
        super.init()
    }

    
    private var subscriber: AnySubscriber<ParserResult, Error>?
    
    @available(OSX 10.15, *)
    var publisher: AnyPublisher<ParserResult, Error> {
        self.eraseToAnyPublisher()
    }
}

@available(OSX 10.15, *)
extension Parser: Publisher {
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = EventSubscription<S>(parser: parser, targetUrl: targetUrl)
        subscription.target = subscriber
        
        subscriber.receive(subscription: subscription)
    }
    
    typealias Output = ParserResult
    
    typealias Failure = Error
}


@available(OSX 10.15, *)
extension Parser: Subscription {
    func request(_ demand: Subscribers.Demand) {
        parser.parse()
    }
    
    func cancel() {
        Swift.print(#line,"cancel")
        parser.abortParsing()
    }
}

@available(OSX 10.15, *)
// こいつがParserDelegateを持つ
class EventSubscription<Target: Subscriber>: NSObject, XMLParserDelegateWrapperDelegate, Subscription
where Target.Input == ParserResult, Target.Failure == Error {
    func xmlParserDelegateWrapper(_ xmlParserDelegateWrapper: XMLParserDelegateWrapper, didCompleteWithResult result: Result<ParserResult, Error>) {
        switch result {
        case .success(let parserResults):
            _ = target?.receive(parserResults)
            target?.receive(completion: .finished)
        case .failure(let error):
            target!.receive(completion: .failure(error))
        }
    }
    
    internal init(parser: XMLParser, targetUrl: URL) {
        self.parser = XMLParserDelegateWrapper(parser: parser, targetUrl: targetUrl)
        super.init()
        self.parser.delegate = self
    }
    
    private let parser: XMLParserDelegateWrapper
    
    var target: Target?
    
    func request(_ demand: Subscribers.Demand) {
        parser.parse()
    }
    
    func cancel() {
        parser.abortParsing()
        target = nil
    }
}

#endif
