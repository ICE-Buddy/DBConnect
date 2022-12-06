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
  
    enum Model: CaseIterable {
        case BR401, BR402, BR403, BR406, BR407, BR408, BR411, BR415, BR412, unknown
        
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
                return [Int](8001...8079)
            case .BR411:
                return [Int](1101...1199)
            case .BR415:
                return [Int](1501...1599)
            case .BR412:
                return [Int](9001...9999)
            case .unknown:
                return []
            }
        }
    }
    
    var triebZugNummer: String
    var model: Model
    
    init(tzn: String) {
        self.model = Model.allCases.first { trainType in
            trainType.triebZugNummern.contains(triebzugnummer: tzn)
        } ?? .unknown
        self.triebZugNummer = tzn
    }
    
  
    
    public var humanReadableTrainType: String {
        switch self.model {
        case .BR401:
            return "ICE 1"
        case .BR402:
            return "ICE 2"
        case .BR403, .BR406, .BR407:
            return "ICE 3"
        case .BR408:
            return "ICE 3 Neo"
        case .BR411, .BR415:
            return "ICE T"
        case .BR412:
            return "ICE 4"
        case .unknown:
            return "Unknown Train Type"
        }
    }
    
    public var trainModel: String {
        "\(self.humanReadableTrainType) (TZN: \(self.triebZugNummer))"
    }
    
    #if os(iOS)
    @available(iOS 13.0, *)
    public var trainIcon: Image? {
        switch self.model {
        case .BR401:
            return Image("BR401")
        case .BR402:
            return Image("BR402")
        case .BR403:
            return Image("BR403")
        case .BR406:
            return Image("BR406")
        case .BR407:
            return Image("BR407")
        case .BR408:
            return Image("BR408")
        case .BR411:
            return Image("BR411")
        case .BR415:
            return Image("BR415")
        case .BR412:
            return Image("BR412")
        case .unknown:
            return Image("BR401")
        }
    }
    #endif
    
    #if os(macOS)
    public var trainIcon: NSImage? {
        switch self.model {
        case .BR401:
            return Bundle.module.image(forResource: "BR401")!
        case .BR402:
            return Bundle.module.image(forResource: "BR402")!
        case .BR403:
            return Bundle.module.image(forResource: "BR403")!
        case .BR406:
            return Bundle.module.image(forResource: "BR406")!
        case .BR407:
            return Bundle.module.image(forResource: "BR407")!
        case .BR408:
            return Bundle.module.image(forResource: "BR408")!
        case .BR411:
            return Bundle.module.image(forResource: "BR411")!
        case .BR415:
            return Bundle.module.image(forResource: "BR415")!
        case .BR412:
            return Bundle.module.image(forResource: "BR412")!
        case .unknown:
            return Bundle.module.image(forResource: "BR401")!
        }
    }
    #endif
    
}

extension Array where Element == Int {
    private func number(number: Int, matchesWithTzn tzn: String) -> Bool {
        tzn.lowercased() == "tz\(number)" || tzn.lowercased() == "tz \(number)" || tzn.lowercased() == "ice\(number)" || tzn.lowercased() == "ice \(number)"
    }
    
    public func contains(triebzugnummer: String) -> Bool {
        self.contains(where: { number in
            self.number(number: number, matchesWithTzn: triebzugnummer)
        })
    }
}
