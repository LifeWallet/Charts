//
//  CandleChartDataProvider.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

@objc
public protocol CandleChartDataProvider: BarLineScatterCandleBubbleChartDataProvider
{
    var candleData: CandleChartData? { get }
    
    //lifewallet CandleChartDataProvider
    var positions: [Float] { get set }
    var lifeWalletShouldHideMedian: Bool { get set }
}
