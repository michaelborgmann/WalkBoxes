//
//  WalkBoxGraph.swift
//  Pods
//
//  Created by Michael Borgmann on 24/02/2017.
//
//

import GameplayKit

public class WalkBoxGraph: GKGraph {
    
    public var polygons: [Polygon] {
        didSet {
            resetPolygonNodes()
        }
    }
    
    public init(polygons: [Polygon]) {
        self.polygons = polygons
        super.init()
        resetPolygonNodes()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func connectNodeToMesh(node: GKGraphNode2D) {
        let nodePoint = float2(node.position.x, node.position.y)
        var intersection: float2!
        var containingPolygon: Polygon!
        var minDistance = FLT_MAX
        
        for polygon in polygons {
            if polygon.contains(nodePoint) {
                intersection = nodePoint
                containingPolygon = polygon
                break
            }
            
            var lastPoint = polygon.points.last!
            for point in polygon.points {
                if let distanceAndIntersection = distanceSquaredAndIntersection(point: nodePoint, toLine: (p1: lastPoint, p2: point)) {
                    if distanceAndIntersection.distanceSquared < minDistance {
                        intersection = distanceAndIntersection.intersection
                        minDistance = distanceAndIntersection.distanceSquared
                        containingPolygon = polygon
                    }
                }
                lastPoint = point
            }
        }
        
        node.position = intersection
        node.addConnections(to: containingPolygon.graphNodes, bidirectional: true)
    }
    
    private func distanceSquaredAndIntersection(point: float2, toLine line: (p1: float2, p2: float2)) -> (distanceSquared: Float, intersection: float2)? {
        
        let (l1, l2) = line
        let lineMagnitude = distance_squared(l1, l2)
        let u = (((point.x - l1.x) * (l2.x - l1.x) + (point.y - l1.y) * (l2.y - l1.y)) / lineMagnitude)
        
        if u < 0.0 || u > 1.0 {
            return nil
        }
        
        let intersection = float2(l1.x + u * (l2.x - l1.x), l1.y + u * (l2.y - l1.y))
        
        return (distanceSquared: distance_squared(point, intersection), intersection: intersection)
    }
    
    public override func findPath(from startNode: GKGraphNode, to endNode: GKGraphNode) -> [GKGraphNode] {
        guard let start = startNode as? GKGraphNode2D, let end = endNode as? GKGraphNode2D else {
            return super.findPath(from: startNode, to: endNode)
        }
        
        for polygon in polygons {
            if polygon.contains(float2(start.position.x, start.position.y)) &&
                polygon.contains(float2(end.position.x, end.position.y)) {
                return [start, end]
            }
        }
        
        return super.findPath(from: startNode, to: endNode)
    }
    
    func resetPolygonNodes() {
        if let nodes = nodes {
            remove(nodes)
        }
        
        var pointToNode: [String: GKGraphNode2D] = [:]
        for polygon in polygons {
            var lastPoint = polygon.points.last!
            var totalPoint = float2(0, 0)
            for point in polygon.points {
                addPoint(point: point, polygon: polygon, pointToNode: &pointToNode)
                
                let midPoint = float2((point.x + lastPoint.x) / 2.0, (point.y + lastPoint.y) / 2.0)
                addPoint(point: midPoint, polygon: polygon, pointToNode: &pointToNode)
                
                lastPoint = point
                totalPoint.x += point.x
                totalPoint.y += point.y
            }
            
            addPoint(point: float2(totalPoint.x / Float(polygon.points.count), totalPoint.y / Float(polygon.points.count)), polygon: polygon, pointToNode: &pointToNode)
            
        }
    }
    
    func addPoint(point: float2, polygon: Polygon, pointToNode: inout [String: GKGraphNode2D]) {
        let graph: GKGraphNode2D
        
        if let node = pointToNode["\(point)"] {
            graph = node
        } else {
            graph = WalkBoxNode(point: point)
            add([graph])
        }
        
        graph.addConnections(to: polygon.graphNodes, bidirectional: true)
        polygon.graphNodes.append(graph)
        pointToNode["\(point)"] = graph
    }
    
}

public class WalkBoxNode : GKGraphNode2D {
    
}
