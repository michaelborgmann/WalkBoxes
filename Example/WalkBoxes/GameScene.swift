//
//  GameScene.swift
//  WalkBoxes
//
//  Created by Michael Borgmann on 24/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import SpriteKit
import GameplayKit
import WalkBoxes
import SwiftyJSON

class GameScene: SKScene {

    fileprivate var label : SKLabelNode?
    
    let sprite = SKSpriteNode(imageNamed: "Spaceship")
    var path: [GKGraphNode2D]?
    let node = SKShapeNode()
    var lastTime: TimeInterval = 0
    var nextPosition: float2?

    // MARK: Walk Boxes Graph
    
    lazy var graph: WalkBoxGraph = {
        var polygons: [Polygon] = []
        
        if let json = self.loadJSON(fileNamed: "WalkBoxes") {
            polygons = self.createPolygonsFromJSON(json)
        }
        
        let graph = WalkBoxGraph(polygons: polygons)
        return graph
    }()
    
    func loadJSON(fileNamed: String) -> JSON? {
        var json: JSON?
        
        do {
            if let file = Bundle.main.url(forResource: fileNamed, withExtension: "json") {
                let data = try Data(contentsOf: file)
                json = JSON(data: data)
                
            }
        } catch {
            print("file not found")
        }
        
        return json
    }
    
    func createPolygonsFromJSON(_ json: JSON) -> [Polygon] {
        var polygons: [Polygon] = []
        
        for polygon in json["rigidBodies"][0]["polygons"].arrayValue {
            var points: [float2] = []
            for point in polygon.arrayValue {
                points.append(float2(x: point["x"].floatValue * Float(self.size.width) - 300.0,
                                     y: point["y"].floatValue * Float(self.size.height) - 150.0))
            }
            polygons.append(Polygon(points: points))
        }
        
        return polygons
    }
    
    // MARK: Class Methods
    
    override func didMove(to view: SKView) {
        self.label = self.childNode(withName: "//label") as? SKLabelNode
        createPolygons()
        createConnections()
        createPath()
        createShip()
    }
    
    // MARK: Nodes
    
    func createPolygons() {
        let path = CGMutablePath()
        
        for polygon in graph.polygons {
            let points = polygon.points
            path.move(to: CGPoint(x: Double(points[0].x),
                                  y: Double(points[0].y)))
            for point in points {
                path.addLine(to: CGPoint(x: Double(point.x),
                                         y: Double(point.y)))
            }
        }
        
        let node = SKShapeNode()
        node.path = path
        node.fillColor = .blue
        node.strokeColor = .green
        addChild(node)
    }
    
    func createConnections() {
        for node in graph.nodes as! [GKGraphNode2D] {
            let path = CGMutablePath()
            for connected in node.connectedNodes as! [GKGraphNode2D] {
                path.move(to: CGPoint(x: Double(node.position.x),
                                      y: Double(node.position.y)))
                path.addLine(to: CGPoint(x: Double(connected.position.x),
                                         y: Double(connected.position.y)))
            }
            let node = SKShapeNode()
            node.path = path
            node.strokeColor = UIColor.yellow
            addChild(node)
        }
    }
    
    func createPath() {
        //let node = SKShapeNode()
        node.strokeColor = UIColor.red
        node.lineWidth = 10
        addChild(node)
    }
    
    func createShip() {
        sprite.position = CGPoint(x: 0, y: -100)
        sprite.xScale = 0.1
        sprite.yScale = 0.1
        addChild(sprite)
    }
    
    // MARK: Input Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let startPosition = float2(sprite.position)
        let endPosition = float2(touch.location(in: self))
        
        let startNode = WalkBoxNode(point: startPosition)
        let endNode = WalkBoxNode(point: endPosition)
        
        graph.connectNodeToMesh(node: startNode)
        graph.connectNodeToMesh(node: endNode)
        
        
        if let path = graph.findPath(from: startNode, to: endNode) as? [GKGraphNode2D] {
            nextPosition = nil
            self.path = path.count > 0 ? path : nil
            
            if path.count > 0 {
                let line = CGMutablePath()
                line.move(to: CGPoint(x: CGFloat(path[0].position.x), y: CGFloat(path[0].position.y)))
                for node in path {
                    line.addLine(to: CGPoint(x: CGFloat(node.position.x), y: CGFloat(node.position.y)))
                }
                node.path = line
            }
        }
        graph.remove([startNode, endNode])
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastTime
        
        if path != nil && nextPosition == nil {
            nextPosition = path![0].position
            path!.remove(at: 0)
            if path!.count == 0 {
                path = nil
            }
        }
        
        if let nextPosition = nextPosition {
            let movemementSpeed = CGFloat(300)
            
            let displacement = nextPosition - float2(sprite.position)
            let angle = CGFloat(atan2(displacement.y, displacement.x))
            let maxPossibleDistanceToMove = movemementSpeed * CGFloat(deltaTime)
            
            let normalizedDispalcement: float2
            if length(displacement) > 0.0 {
                normalizedDispalcement = normalize(displacement)
            } else {
                normalizedDispalcement = displacement
            }
            
            let actualDistanceToMove = CGFloat(length(normalizedDispalcement)) * maxPossibleDistanceToMove
            
            let dx = actualDistanceToMove * cos(angle)
            let dy = actualDistanceToMove * sin(angle)
            
            sprite.position = CGPoint(x: sprite.position.x + dx, y: sprite.position.y + dy)
            sprite.zRotation = atan2(-dx, dy)
            
            if length(displacement) <= Float(maxPossibleDistanceToMove) {
                self.nextPosition = nil
            }
        }
        lastTime = currentTime
    }
    
}

// MARK: Extensions to convert between CGPoint and float2

extension CGPoint {
    init(_ point: float2) {
        x = CGFloat(point.x)
        y = CGFloat(point.y)
    }
}

extension float2 {
    init(_ point: CGPoint) {
        self.init(x: Float(point.x), y: Float(point.y))
    }
}
