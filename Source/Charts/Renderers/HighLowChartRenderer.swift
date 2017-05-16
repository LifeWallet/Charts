//
//  HighLowChartRenderer.swift
//  Charts
//
//  Created by Mike Leveton on 5/7/17.
//
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif


open class HighLowChartRenderer: LineScatterCandleRadarRenderer{
    open weak var dataProvider: CandleChartDataProvider?
    
    //lifewallet
    open var dounutRenderer = ScatterChartDataSet.renderer(forShape: ScatterChartDataSet.Shape(rawValue: 1)!)
    open var innerRectRenderer = ScatterChartDataSet.renderer(forShape: ScatterChartDataSet.Shape(rawValue: 0)!)
    
    public init(dataProvider: CandleChartDataProvider?, animator: Animator?, viewPortHandler: ViewPortHandler?){
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.dataProvider = dataProvider
    }
    
    open override func drawData(context: CGContext){
        guard let dataProvider = dataProvider, let candleData = dataProvider.candleData else { return }
        
        for set in candleData.dataSets as! [ICandleChartDataSet]{
            if set.isVisible{
                drawDataSet(context: context, dataSet: set)
            }
        }
    }
    
    //lifewallet - the formula is to get a quarter of the difference between high and low, and then add this quarter to the low and subtract it from the high.
    func firstAndLastQuarterFromRange(low:Double, high:Double) -> (bottom:Double, top:Double){
        let range = high - low
        let diff = range * 0.25
        let topQuarter = high - diff
        let bottomQuarter = low + diff
        return (bottomQuarter, topQuarter)
    }
    
    fileprivate var _rangePoints = [CGPoint](repeating: CGPoint(), count: 2)
    
    open func drawDataSet(context: CGContext, dataSet: ICandleChartDataSet){
        guard let
            dataProvider = dataProvider,
            let animator = animator
            else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        let phaseY = animator.phaseY
        
        
        _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
        
        context.saveGState()
        
        //todo: make dynamic
        //context.setLineWidth(dataSet.shadowWidth)
        context.setLineWidth(7.0)
        
        //lifewallet
        var positionArray = [Float]()
        
        for j in stride(from: _xBounds.min, through: _xBounds.range + _xBounds.min, by: 1){
            // get the entry
            guard let e = dataSet.entryForIndex(j) as? CandleChartDataEntry else { continue }
            
            let xPos = e.x
            let high = e.high
            let low = e.low
            let tup = firstAndLastQuarterFromRange(low: low, high: high)
            
            //lifewallet edit - don't draw shape if it's 0
            if (high < 0.1 && low < 0.1){
                continue
            }
            
            _rangePoints[0].x = CGFloat(xPos)
            _rangePoints[0].y = CGFloat(high * phaseY)
            _rangePoints[1].x = CGFloat(xPos)
            _rangePoints[1].y = CGFloat(low * phaseY)
            
            var highPt = CGPoint()
            highPt.x = CGFloat(xPos)
            highPt.y = CGFloat(high * phaseY)
            highPt = highPt.applying(valueToPixelMatrix)
            
            var lowPt = CGPoint()
            lowPt.x = CGFloat(xPos)
            lowPt.y = CGFloat(low * phaseY)
            lowPt = lowPt.applying(valueToPixelMatrix)
            
            var bottomQuarterPt = CGPoint()
            bottomQuarterPt.x = CGFloat(xPos)
            bottomQuarterPt.y = CGFloat(tup.bottom * phaseY)
            bottomQuarterPt = bottomQuarterPt.applying(valueToPixelMatrix)
            
            var topQuarterPt = CGPoint()
            topQuarterPt.x = CGFloat(xPos)
            topQuarterPt.y = CGFloat(tup.top * phaseY)
            topQuarterPt = topQuarterPt.applying(valueToPixelMatrix)
            
            //lifewallet - create a dounut for each high and low point
            dounutRenderer.renderShapeForHighLowChart!(context: context, dataSet: dataSet, viewPortHandler: self.viewPortHandler!, point: highPt, color: UIColor.white)
            dounutRenderer.renderShapeForHighLowChart!(context: context, dataSet: dataSet, viewPortHandler: self.viewPortHandler!, point: lowPt, color: UIColor.white)
            
            //don't show middle fifty percent if it's going to take over the whole line
            if e.high - e.low > 2 {
                let rect = CGRect(x: highPt.x - 3.5, y: topQuarterPt.y, width: 7.0, height: bottomQuarterPt.y - topQuarterPt.y)
                innerRectRenderer.renderSquareForHighLowChart!(context: context, dataSet: dataSet, viewPortHandler: self.viewPortHandler!, rect: rect, color: UIColor.white)
            }
            
            positionArray.append(Float(highPt.x - 3.5))
            
            //lifewallet - change line width back bc renderer changes it.
            context.setLineWidth(7.0)
            
            trans.pointValuesToPixel(&_rangePoints)
            
            // draw the ranges
            let barColor = dataSet.neutralColor ?? dataSet.color(atIndex: j)
            
            
            context.setStrokeColor(barColor.cgColor)
            context.setLineCap(CGLineCap.round)
            context.strokeLineSegments(between: _rangePoints)

        }
        
        dataProvider.positions = positionArray
        context.restoreGState()
    }
    
    open override func drawValues(context: CGContext){
        guard
            let dataProvider = dataProvider,
            let viewPortHandler = self.viewPortHandler,
            let candleData = dataProvider.candleData,
            let animator = animator
            else { return }
        
        // if values are drawn
        if isDrawingValuesAllowed(dataProvider: dataProvider){
            var dataSets = candleData.dataSets
            
            let phaseY = animator.phaseY
            
            var pt = CGPoint()
            
            //lifewallet
            var lowPoint = CGPoint()
            
            for i in 0 ..< dataSets.count{
                guard let dataSet = dataSets[i] as? IBarLineScatterCandleBubbleChartDataSet
                    else { continue }
                
                print("high low chart dataset: \(dataSet)")
                if !shouldDrawValues(forDataSet: dataSet)
                {
                    continue
                }
                
                let valueFont = dataSet.valueFont
                
                guard let formatter = dataSet.valueFormatter else { continue }
                
                let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
                let valueToPixelMatrix = trans.valueToPixelMatrix
                
                let iconsOffset = dataSet.iconsOffset
                
                _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)
                
                let lineHeight = valueFont.lineHeight
                let yOffset: CGFloat = lineHeight + 5.0
                
                for j in stride(from: _xBounds.min, through: _xBounds.range + _xBounds.min, by: 1)
                {
                    guard let e = dataSet.entryForIndex(j) as? CandleChartDataEntry else { break }
                    //print("e high \(e.high) e low \(e.low)")
                    pt.x = CGFloat(e.x)
                    pt.y = CGFloat(e.high * phaseY)
                    pt = pt.applying(valueToPixelMatrix)
                    
                    //lifewallet
                    lowPoint.x = CGFloat(e.x)
                    lowPoint.y = CGFloat(e.low)
                    lowPoint = lowPoint.applying(valueToPixelMatrix)
                    
                    if (!viewPortHandler.isInBoundsRight(pt.x))
                    {
                        break
                    }
                    
                    if (!viewPortHandler.isInBoundsLeft(pt.x) || !viewPortHandler.isInBoundsY(pt.y))
                    {
                        continue
                    }
                    
                    //lifewallet
                    let lifeWalletHighLowLooksBetterPlain:Bool = false
                    if dataSet.isDrawValuesEnabled && !(e.high < 0.1 && e.low < 0.1) && lifeWalletHighLowLooksBetterPlain
                    {
                        let highString = formatter.stringForValue(e.high, entry: e, dataSetIndex: i, viewPortHandler: viewPortHandler)
                        
                        /* high values */
                        ChartUtils.drawText(
                            context: context,
                            text: highString,
                            point: CGPoint(
                                x: pt.x,
                                y: pt.y - yOffset),
                            align: .center,
                            attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)])
                        
                        
                        let lowString = formatter.stringForValue(e.low, entry: e, dataSetIndex: i, viewPortHandler: viewPortHandler)
                        /* low values */
                        ChartUtils.drawText(
                            context: context,
                            text: lowString,
                            point: CGPoint(
                                x: lowPoint.x,
                                y: lowPoint.y + 5.0),
                            align: .center,
                            attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: dataSet.valueTextColorAt(j)])
                    }
                    
                    if let icon = e.icon, dataSet.isDrawIconsEnabled
                    {
                        ChartUtils.drawImage(context: context,
                                             image: icon,
                                             x: pt.x + iconsOffset.x,
                                             y: pt.y + iconsOffset.y,
                                             size: icon.size)
                    }
                }
            }
        }
    }
    
    open override func drawExtras(context: CGContext)
    {
    }
    
    open override func drawHighlighted(context: CGContext, indices: [Highlight])
    {
        guard
            let dataProvider = dataProvider,
            let candleData = dataProvider.candleData,
            let animator = animator
            else { return }
        
        context.saveGState()
        
        for high in indices
        {
            guard
                let set = candleData.getDataSetByIndex(high.dataSetIndex) as? ICandleChartDataSet,
                set.isHighlightEnabled
                else { continue }
            
            guard let e = set.entryForXValue(high.x, closestToY: high.y) as? CandleChartDataEntry else { continue }
            
            if !isInBoundsX(entry: e, dataSet: set)
            {
                continue
            }
            
            let trans = dataProvider.getTransformer(forAxis: set.axisDependency)
            
            context.setStrokeColor(set.highlightColor.cgColor)
            context.setLineWidth(set.highlightLineWidth)
            
            if set.highlightLineDashLengths != nil
            {
                context.setLineDash(phase: set.highlightLineDashPhase, lengths: set.highlightLineDashLengths!)
            }
            else
            {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            let lowValue = e.low * Double(animator.phaseY)
            let highValue = e.high * Double(animator.phaseY)
            let y = (lowValue + highValue) / 2.0
            
            let pt = trans.pixelForValues(x: e.x, y: y)
            
            high.setDraw(pt: pt)
            
            // draw the lines
            drawHighlightLines(context: context, point: pt, set: set)
        }
        
        context.restoreGState()
    }
}
