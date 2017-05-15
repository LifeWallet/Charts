//
//  LifeWalletFormatter.swift
//  Charts
//
//  Created by Mike Leveton on 5/15/17.
//
//

import UIKit

@objc(ILifeWalletValueFormatter)
public protocol LifeWalletFormatter: NSObjectProtocol {
    
    func dataForGraph(positions:Array<Float>, leftBorder:Float, width:Float)
}
