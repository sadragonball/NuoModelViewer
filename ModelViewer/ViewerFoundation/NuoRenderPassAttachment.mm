//
//  NuoRenderPassAttachment.m
//  ModelViewer
//
//  Created by Dong on 5/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRenderPassAttachment.h"
#import "NuoRenderPassTarget.h"



@implementation NuoRenderPassAttachment
{
    id<MTLTexture> _sampleTexture;
}


- (void)makeTexture
{
    BOOL drawableSizeChanged = false;
    if (_texture.width != _drawableSize.width || _texture.height != _drawableSize.height)
        drawableSizeChanged = true;
    
    BOOL sampleCountChanged = false;
    if (_sampleCount > 1 && !_sampleTexture)
        sampleCountChanged = true;
    if (_sampleCount != _sampleTexture.sampleCount)
        sampleCountChanged = true;
    
    if (!drawableSizeChanged && !sampleCountChanged)
        return;
        
        
    if (_needResolve || _sampleCount == 1)
    {
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_pixelFormat
                                                                                        width:_drawableSize.width
                                                                                       height:_drawableSize.height
                                                                                    mipmapped:NO];
        
        
        
        desc.sampleCount = 1;
        desc.textureType = MTLTextureType2D;
        desc.resourceOptions = MTLResourceStorageModePrivate;
        desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        
        _texture = [_device newTextureWithDescriptor:desc];
        [_texture setLabel:_name];
    }
    
    if (_sampleCount > 1 && _needResolve)
    {
        MTLTextureDescriptor *sampleDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_pixelFormat
                                                                                              width:_drawableSize.width
                                                                                             height:_drawableSize.height
                                                                                          mipmapped:NO];
        
        sampleDesc.sampleCount = _sampleCount;
        sampleDesc.textureType = MTLTextureType2DMultisample;
        sampleDesc.resourceOptions = MTLResourceStorageModePrivate;
        sampleDesc.usage = MTLTextureUsageRenderTarget;
        
        _sampleTexture = [_device newTextureWithDescriptor:sampleDesc];
        
        NSString* name = [NSString stringWithFormat:@"%@ Sample", _name];
        [_sampleTexture setLabel:name];
    }
}


- (MTLRenderPassAttachmentDescriptor*)descriptor
{
    MTLRenderPassAttachmentDescriptor* result = nil;
    
    if (_type == kNuoRenderPassAttachment_Color)
    {
        result = [MTLRenderPassColorAttachmentDescriptor new];
        ((MTLRenderPassColorAttachmentDescriptor*)result).clearColor = _clearColor;
    }
    
    if (_type == kNuoRenderPassAttachment_Depth)
    {
        result = [MTLRenderPassDepthAttachmentDescriptor new];
    }
        
    result.texture = (_sampleCount == 1) ? _texture : _sampleTexture;
    result.loadAction = _needClear ? NUO_LOAD_ACTION : MTLLoadActionDontCare;
    
    if (_needStore)
    {
        if (_sampleCount > 1 && _needResolve)
        {
            result.storeAction = MTLStoreActionMultisampleResolve;
            result.resolveTexture = _texture;
        }
        else
        {
            result.storeAction = MTLStoreActionStore;
        }
    }
    else
    {
        result.storeAction = MTLStoreActionDontCare;
    }

    return result;
}


@end