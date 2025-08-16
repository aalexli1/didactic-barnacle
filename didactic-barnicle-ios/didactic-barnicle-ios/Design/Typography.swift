//
//  Typography.swift
//  didactic-barnicle-ios
//
//  Created by Auto Agent on 8/14/25.
//

import SwiftUI

struct Typography {
    enum FontSize: CGFloat {
        case largeTitle = 34
        case title1 = 28
        case title2 = 22
        case title3 = 20
        case headline = 17
        case body = 17
        case callout = 16
        case subheadline = 15
        case footnote = 13
        case caption1 = 12
        case caption2 = 11
    }
    
    struct Fonts {
        static func largeTitle(_ weight: Font.Weight = .bold) -> Font {
            Font.system(size: FontSize.largeTitle.rawValue, weight: weight, design: .rounded)
        }
        
        static func title1(_ weight: Font.Weight = .bold) -> Font {
            Font.system(size: FontSize.title1.rawValue, weight: weight, design: .rounded)
        }
        
        static func title2(_ weight: Font.Weight = .semibold) -> Font {
            Font.system(size: FontSize.title2.rawValue, weight: weight, design: .rounded)
        }
        
        static func title3(_ weight: Font.Weight = .semibold) -> Font {
            Font.system(size: FontSize.title3.rawValue, weight: weight, design: .rounded)
        }
        
        static func headline(_ weight: Font.Weight = .semibold) -> Font {
            Font.system(size: FontSize.headline.rawValue, weight: weight)
        }
        
        static func body(_ weight: Font.Weight = .regular) -> Font {
            Font.system(size: FontSize.body.rawValue, weight: weight)
        }
        
        static func callout(_ weight: Font.Weight = .regular) -> Font {
            Font.system(size: FontSize.callout.rawValue, weight: weight)
        }
        
        static func subheadline(_ weight: Font.Weight = .regular) -> Font {
            Font.system(size: FontSize.subheadline.rawValue, weight: weight)
        }
        
        static func footnote(_ weight: Font.Weight = .regular) -> Font {
            Font.system(size: FontSize.footnote.rawValue, weight: weight)
        }
        
        static func caption1(_ weight: Font.Weight = .regular) -> Font {
            Font.system(size: FontSize.caption1.rawValue, weight: weight)
        }
        
        static func caption2(_ weight: Font.Weight = .regular) -> Font {
            Font.system(size: FontSize.caption2.rawValue, weight: weight)
        }
    }
}

extension View {
    func appFont(_ style: @escaping (Font.Weight) -> Font, weight: Font.Weight = .regular) -> some View {
        self.font(style(weight))
    }
}