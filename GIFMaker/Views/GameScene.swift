//
//  GameScene.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/13/20.
//

import SpriteKit

class GameScene: SKScene {
    enum Shapes: String, CaseIterable {
        case Oval
        case Triangle
        case Rectangle
    }
    private var popping = false
    private var emitter: SKEmitterNode?
    private var emitterBirthRate: CGFloat = 0

    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)

        setupParticles()
        setupFloor()
        setupItems()
    }

    private func setupFloor() {
        let size = CGSize(width: frame.width + 100, height: 4)
        let floor = SKSpriteNode(color: .clear, size: size)
        floor.name = "floor"
        floor.position = CGPoint(x: size.width / 2, y: 0)
        floor.physicsBody = SKPhysicsBody(rectangleOf: size)
        floor.physicsBody?.isDynamic = false
        floor.physicsBody?.contactTestBitMask = 0x1 << 0
        addChild(floor)
    }

    private func setupItems() {
        var i: Int = 0
        for value in Shapes.allCases {
            add(at: CGPoint(x: 30 + CGFloat(i * 50), y: frame.height / 2), imageName: value.rawValue)
            i += 1
        }
    }

    private func setupParticles() {
        guard let emitter = SKEmitterNode(fileNamed: "Confetti.sks") else { return }
        emitterBirthRate = emitter.particleBirthRate
        emitter.particleBirthRate = 0
        emitter.position = CGPoint(x: frame.width / 2, y: frame.height)
        addChild(emitter)
        self.emitter = emitter
    }

    func add(at position: CGPoint, imageName: String) {
        guard let image = NSImage(named: imageName) else { return }
        let texture = SKTexture(image: image)
        let box = SKSpriteNode(texture: texture)
        box.name = "box"
        box.position = position
        box.physicsBody = SKPhysicsBody(texture: texture, size: CGSize(width: 36, height: 36))
        box.physicsBody?.contactTestBitMask = 0x1 << 0
        box.physicsBody?.fieldBitMask = 1 << 2
        addChild(box)
    }

    func beginPopping() {
        popping = true
        emitter?.particleBirthRate = emitterBirthRate
        for child in children {
            if child.name == "box" {
                guard let body = child.physicsBody else { continue }
                pop(body: body)
            }
        }
    }

    func stopPopping() {
        popping = false
        emitter?.particleBirthRate = 0
    }

    func pop(body: SKPhysicsBody) {
        let value = 20
        body.applyImpulse(CGVector(dx: Int.random(in: -value...value), dy: value))
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        guard popping else { return }
        if contact.bodyA.node?.name == "floor" {
            pop(body: contact.bodyB)
        } else if contact.bodyB.node?.name == "floor" {
            pop(body: contact.bodyA)
        }
    }
}
