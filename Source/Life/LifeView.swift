//
//  ViewBase.swift
//  Spirographer
//
//  Created by Connor yass on 3/17/19.
//  Copyright © 2019 HSY_Technologies. All rights reserved.
//

import SwiftUI
import MetalKit
import simd

final class LifeMTKView: MTKView {
    
    struct FragmentUniforms {
        var inactiveColor: SIMD4<Float>
        var activeColor: SIMD4<Float>
    }
    
    // MARK: Properties
    
    let width: Int
    let height: Int
    
    // MARK: Variables
    
    var vertexBuffer: MTLBuffer!
    
    private let vertexData: [Float] = [
        -1.0, -1.0, 0.0, 1.0,
         1.0, -1.0, 0.0, 1.0,
        -1.0,  1.0, 0.0, 1.0,
        -1.0,  1.0, 0.0, 1.0,
         1.0, -1.0, 0.0, 1.0,
         1.0,  1.0, 0.0, 1.0
    ]
    
    private var commandQueue: MTLCommandQueue!
    
    private var pipelineState: MTLRenderPipelineState!
    
    private var computeState: MTLComputePipelineState!
    
    private var generationA: MTLTexture!
    
    private var generationB: MTLTexture!
    
    private(set) var generation: UInt64 = 0
    
    private func getTexture(nextGeneration: Bool = false) -> MTLTexture {
        if nextGeneration {
            return generation % 2 == 0 ? generationB : generationA
        } else {
            return generation % 2 == 0 ? generationA : generationB
        }
    }
    
    // MARK: Lifecycle
    
    init(width: UInt, height: UInt) {
        self.width = Int(width)
        self.height = Int(height)
        
        super.init(frame: .zero, device: nil)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        device = MTLCreateSystemDefaultDevice()
        isPaused = true
        enableSetNeedsDisplay = true
        
        let dataSize = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device!.makeBuffer(bytes: vertexData, length: dataSize, options: [])!
        
        let library = device!.makeDefaultLibrary()
        let fragmentProgram = library!.makeFunction(name: "fragment_shader")
        let vertexProgram = library!.makeFunction(name: "vertex_shader")
        let computeFunction = library!.makeFunction(name: "compute_function")
        
        clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        backgroundColor = .clear
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            pipelineState = try device!.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error as NSError {
            print(error);
        }
        
        do {
            pipelineState = try device!.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error as NSError {
            print(error);
        }
        
        do {
            computeState = try device!.makeComputePipelineState(function: computeFunction!)
        } catch let error as NSError {
            print(error);
        }
        
        commandQueue = device!.makeCommandQueue()
        
        (generationA, generationB) = Self.makeTextures(
            device: device!,
            width: width,
            height: height
        )
        
        randomize()
    }
    
    static func makeTextures(device: MTLDevice, width: Int, height: Int) -> (MTLTexture, MTLTexture) {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.storageMode = .shared
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        textureDescriptor.pixelFormat = .r8Uint
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.depth = 1
        
        let generationA = device.makeTexture(descriptor: textureDescriptor)!
        let generationB = device.makeTexture(descriptor: textureDescriptor)!
        
        return (generationA, generationB)
    }
    
    // MARK: Functions
    
    func step() {
        generation += 1
        setNeedsDisplay()
    }
    
    func randomize() {
        generation = 0
        
        var seed = [UInt8](repeating: 0, count: width * height)
        let numberOfCells = width * height
        let numberOfLiveCells = Int(pow(Double(numberOfCells), 0.8))
        for _ in (0..<numberOfLiveCells) {
            let r = (0..<numberOfCells).randomElement()!
            seed[r] = 1
        }
        
        getTexture().replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: seed,
            bytesPerRow: width * MemoryLayout<UInt8>.stride
        )
    }
    
    override func draw(_ rect: CGRect) {
        guard let buffer = commandQueue.makeCommandBuffer(),
            let desc = currentRenderPassDescriptor,
            let renderEncoder = buffer.makeRenderCommandEncoder(descriptor: desc)
            else { return }
        
        var uniforms = FragmentUniforms(
            inactiveColor: SIMD4<Float>(0,0,0,1),
            activeColor: SIMD4<Float>(1,1,1,1)
        )
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(getTexture(), index: 0)
        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
        
        guard let computeEncoder = buffer.makeComputeCommandEncoder()
            else { return }
        
        computeEncoder.setComputePipelineState(computeState)
        computeEncoder.setTexture(getTexture(), index: 0)
        computeEncoder.setTexture(getTexture(nextGeneration: true), index: 1)
        
        let threadWidth = computeState.threadExecutionWidth
        let threadHeight = computeState.maxTotalThreadsPerThreadgroup / threadWidth
        let threadsPerThreadgroup = MTLSizeMake(threadWidth, threadHeight, 1)
        let threadsPerGrid = MTLSizeMake(width, height, 1)
        
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        
        if let drawable = currentDrawable {
            buffer.present(drawable)
        }
        buffer.commit()
    }
}
    
// MARK: -

struct LifeView: UIViewRepresentable {
    typealias UIViewType = LifeMTKView
    
    let width: UInt
    let height: UInt
    
    func makeCoordinator() -> LifeView.Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<LifeView>) -> LifeMTKView {
        return LifeMTKView(width: width, height: height)
    }
    
    func updateUIView(_ uiView: LifeMTKView, context: UIViewRepresentableContext<LifeView>) {
        uiView.setNeedsDisplay()
    }
    
    class Coordinator: NSObject {
        var parent: LifeView
        
        init(_ parent: LifeView) {
            self.parent = parent
        }
    }
}

#if DEBUG
struct LifeView_Previews: PreviewProvider {
    
    static var previews: some View {
        LifeView(width: 50, height: 50)
            .previewLayout(.fixed(width: 100, height: 100))
    }
}
#endif
