//
//  TrainMapping.swift
//  ICE Buddy
//
//  Created by Maximilian Seiferth on 04.02.22.
//

import Foundation
import SwiftUI
import TrainConnect
#if targetEnvironment(macCatalyst)
import AppKit
#endif

#if !os(macOS)
import UIKit
#endif

public struct ICETrainType: TrainType {
  
    public enum Model: String, CaseIterable {
        case BR401, BR402, BR403, BR406, BR407, BR408, BR411, BR415, BR412, ICE_L, unknown
        
        var triebZugNummern: [Int] {
            switch self {
            case .BR401:
                return [Int](101...199)
            case .BR402:
                return [Int](201...299)
            case .BR403:
                return [Int](301...399)
            case .BR406:
                return [Int](4601...4699)
            case .BR407:
                return [Int](701...799) + [Int](4701...4799)
            case .BR408:
                return [Int](8001...8090)
            case .BR411:
                return [Int](1101...1199)
            case .BR415:
                return [Int](1501...1599)
            case .BR412:
                return [Int](9001...9050) + [Int](9201...9237) + [Int](9451...9500)
            case .ICE_L:
                return [] // Identified from the reported series, not guessed from service numbers.
            case .unknown:
                return []
            }
        }
    }
    
    public let trainsetIdentifier: String
    public let model: Model

    /// `tzn` is a physical trainset identifier. A service number (e.g. ICE 221) is unrelated.
    /// An explicitly reported, recognized vehicle series takes precedence over number inference.
    public init(tzn: String, series: String? = nil) {
        self.trainsetIdentifier = tzn.trimmingCharacters(in: .whitespacesAndNewlines)
        let reported = series?.uppercased().filter { !$0.isWhitespace }
        let family = reported?.split(separator: ".").first.map(String.init)
        if let family = family,
           let known = Model(rawValue: family.hasPrefix("BR") ? family : "BR" + family), known != .unknown {
            self.model = known
        } else if family == "105" || reported == "ICEL" || reported == "ICE_L" {
            self.model = .ICE_L
        } else if let number = Self.trainsetNumber(tzn) {
            self.model = Model.allCases.first { $0.triebZugNummern.contains(number) } ?? .unknown
        } else {
            self.model = .unknown
        }
    }

    private static func trainsetNumber(_ identifier: String) -> Int? {
        let text = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = try? NSRegularExpression(pattern: "^(?:(?:tzn|tz|ice)\\s*)?([0-9]{1,5})$", options: .caseInsensitive)
            .firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return Int(text[range])
    }

    public var humanReadableTrainType: String {
        switch self.model {
        case .BR401:
            return "ICE 1"
        case .BR402:
            return "ICE 2"
        case .BR403:
            return "ICE 3"
        case .BR406:
            return "ICE 3M"
        case .BR407:
            return "ICE 3 Velaro D"
        case .BR408:
            return "ICE 3neo"
        case .BR411, .BR415:
            return "ICE T"
        case .BR412:
            return "ICE 4"
        case .ICE_L:
            return "ICE L"
        case .unknown:
            return "Unknown train type"
        }
    }
    
    public var trainModel: String {
        let series = model == .unknown || model == .ICE_L ? "" : " · \(model.rawValue.replacingOccurrences(of: "BR", with: "BR "))"
        let identifier = trainsetIdentifier.isEmpty ? "" : " · Tz \(Self.trainsetNumber(trainsetIdentifier).map(String.init) ?? trainsetIdentifier)"
        return "\(humanReadableTrainType)\(series)\(identifier)"
    }

    private var assetName: String {
        model == .unknown ? "train_unknown" : model.rawValue
    }

    #if os(iOS)
    public var trainIcon: Image? { Image(assetName, bundle: Bundle.module) }
    #endif

    #if os(macOS)
    public var trainIcon: NSImage? {
        Bundle.module.image(forResource: assetName)
            ?? NSImage(systemSymbolName: "tram.fill", accessibilityDescription: humanReadableTrainType)
    }
    #endif
}
