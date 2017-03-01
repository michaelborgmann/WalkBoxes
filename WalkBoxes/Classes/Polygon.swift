//
//  Polygon.swift
//  Pods
//
//  Created by Michael Borgmann on 24/02/2017.
//
//

import GameplayKit

public class Polygon {
    
    public let points: [float2]
    public var graphNodes: [GKGraphNode2D] = []
    
    public init(points: [float2]) {
        self.points = points
    }
    
    public func contains(_ point: float2) -> Bool {
        var contains = false

        var j = points.count - 1
        for i in 0..<points.count {
            if ((points[i].y > point.y) != (points[j].y > point.y)) &&
                (point.x < (points[j].x - points[i].x) * (point.y - points[i].y) / (points[j].y - points[i].y) + points[i].x) {

                contains = !contains
            }
            j = i + 1
        }
        
        return contains
    }
    
}
