//
//  HighLowChartView.swift
//  Charts
//
//  Created by Mike Leveton on 5/7/17.
//
//

import Foundation
import CoreGraphics

open class HighLowChartView: BarLineChartViewBase, CandleChartDataProvider
{
    internal override func initialize()
    {
        super.initialize()
        
        renderer = HighLowChartRenderer(dataProvider: self, animator: _animator, viewPortHandler: _viewPortHandler)
        
        self.xAxis.spaceMin = 0.5
        self.xAxis.spaceMax = 0.5
    }
    
    // MARK: - CandleChartDataProvider
    
    open var candleData: CandleChartData?
    {
        return _data as? CandleChartData
    }
    
    open var positions = [Float]()
}
