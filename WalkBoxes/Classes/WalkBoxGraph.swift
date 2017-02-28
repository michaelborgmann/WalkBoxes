//
//  WalkBoxGraph.swift
//  Pods
//
//  Created by Michael Borgmann on 24/02/2017.
//
//

import GameplayKit

public class WalkBoxGraph: GKGraph {
    
    public var polygons: [Polygon] = []
    
    public init(polygons: [Polygon]) {
        self.polygons = polygons
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

public class WalkBoxNode : GKGraphNode2D {
    
}
