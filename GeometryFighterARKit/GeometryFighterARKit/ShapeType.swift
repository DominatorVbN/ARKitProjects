//
//  ShapeType.swift
//  GeometryFighter
//
//  Created by mac on 01/02/19.
//  Copyright © 2019 MMF. All rights reserved.
//

import Foundation
enum ShapeType:Int {
    case Box = 0
    case Sphere
    case Pyramid
    case Torus
    case Capsule
    case Cylinder
    case Cone
    case Tube
    
    //function retirning random shaptype.
    static func random()->ShapeType{
        let maxValue = Tube.rawValue
        let rand = arc4random_uniform(UInt32(maxValue+1))
        return ShapeType(rawValue: Int(rand))!
    }
}
