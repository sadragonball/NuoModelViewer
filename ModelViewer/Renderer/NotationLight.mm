//
//  NotationLight.m
//  ModelViewer
//
//  Created by middleware on 11/13/16.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NotationLight.h"

#import "NuoMesh.h"
#import "NuoMathUtilities.h"

#include "NuoModelArrow.h"
#include <memory>

#include "NuoUniforms.h"
#include "NuoMeshUniform.h"

#import "NuoLightSource.h"
#import "NuoMeshBounds.h"



@interface NotationLight()


@property (nonatomic, strong) NSArray<id<MTLBuffer>>* characterUniformBuffers;

@property (nonatomic, strong) NuoMesh* lightVector;


@end



@implementation NotationLight


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue isBold:(BOOL)bold
{
    self = [super init];
    
    if (self)
    {
        [self makeResources:commandQueue];
        
        float bodyLength = bold ? 1.2 : 1.0;
        float bodyRadius = bold ? 0.24 : 0.2;
        float headLength = bold ? 1.2 : 1.0;
        float headRadius = bold ? 0.36 : 0.3;
        
        PNuoModelArrow arrow = std::make_shared<NuoModelArrow>(bodyLength, bodyRadius, headLength, headRadius);
        arrow->CreateBuffer();
        
        NuoMeshBounds* meshBounds = [NuoMeshBounds new];
        *((NuoBounds*)[meshBounds boundingBox]) = arrow->GetBoundingBox();
        
        _lightVector = [[NuoMesh alloc] initWithCommandQueue:commandQueue
                                    withVerticesBuffer:arrow->Ptr() withLength:arrow->Length()
                                           withIndices:arrow->IndicesPtr() withLength:arrow->IndicesLength()];
        
        MTLRenderPipelineDescriptor* pipelineDesc = [_lightVector makePipelineStateDescriptor];
        
        // if no MSAA, shoud uncomment the following line
        // pipelineDesc.sampleCount = 1;
        
        [_lightVector setBoundsLocal:meshBounds];
        [_lightVector makePipelineState:pipelineDesc];
        [_lightVector makeDepthStencilState];
    }
    
    return self;
}


- (NuoMeshBounds*)bounds
{
    return _lightVector.bounds;
}


- (void)makeResources:(id<MTLCommandQueue>)commandQueue
{
    id<MTLBuffer> characters[kInFlightBufferCount];
    for (size_t i = 0; i < kInFlightBufferCount; ++i)
    {
        id<MTLBuffer> characterUniformBuffers = [commandQueue.device newBufferWithLength:sizeof(NuoModelCharacterUniforms)
                                                                         options:MTLResourceOptionCPUCacheModeDefault];
        characters[i] = characterUniformBuffers;
    }
    
    _characterUniformBuffers = [[NSArray alloc] initWithObjects:characters count:kInFlightBufferCount];
}


- (void)updateUniformsForView:(unsigned int)inFlight
{
    NuoLightSource* desc = _lightSourceDesc;
    struct NuoBoundsBase* bounds = [_lightVector.boundsLocal boundingBox];
    
    const vector_float3 translationToCenter =
    {
        - bounds->_center.x,
        - bounds->_center.y,
        - bounds->_center.z + bounds->_span.z / 2.0f
    };
    
    const matrix_float4x4 modelCenteringMatrix = matrix_translation(translationToCenter);
    const matrix_float4x4 modelMatrix = matrix_rotation_append(modelCenteringMatrix, desc.lightingRotationX, desc.lightingRotationY);
    [_lightVector updateUniform:inFlight withTransform:modelMatrix];
    
    NuoModelCharacterUniforms characters;
    characters.opacity = _selected ? 1.0f : 0.1f;
    
    memcpy([self.characterUniformBuffers[inFlight] contents], &characters, sizeof(characters));
}


- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    [_lightVector setTransparency:!_selected];
    [_lightVector makeDepthStencilState];
}


- (CGPoint)headPointProjected
{
    NuoLightSource* desc = _lightSourceDesc;
    
    matrix_float4x4 rotationMatrix = matrix_rotate(desc.lightingRotationX,
                                                   desc.lightingRotationY);
    
    const vector_float4 startVec = { 0, 0, 1, 1 };
    vector_float4 projected = matrix_multiply(rotationMatrix, startVec);
    
    return CGPointMake(projected.x / projected.w, projected.y / projected.w);
}



- (void)drawWithRenderPass:(id<MTLRenderCommandEncoder>)renderPass
              withInFlight:(unsigned int)inFlight
{
    [self updateUniformsForView:inFlight];
    [renderPass setFragmentBuffer:self.characterUniformBuffers[inFlight] offset:0 atIndex:1];
    
    // the light vector notation does not have varying uniform,
    // use only the 0th buffer
    //
    [_lightVector drawMesh:renderPass indexBuffer:inFlight];
}



@end
