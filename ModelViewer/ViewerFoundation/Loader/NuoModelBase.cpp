//
//  NuoModelBase.cpp
//  ModelViewer
//
//  Created by middleware on 8/28/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#include "NuoModelBase.h"
#include "NuoModelTextured.h"
#include "NuoModelMaterialedBasic.h"
#include "NuoMaterial.h"




std::shared_ptr<NuoModelBase> CreateModel(NuoModelOption& options, const NuoMaterial& material)
{
    if (!material.HasTextureDiffuse())
        options._textured = false;
    
    if (!options._textured && !options._basicMaterialized)
    {
        return std::make_shared<NuoModelSimple>();
    }
    else if (options._textured && !options._basicMaterialized)
    {
        auto model = std::make_shared<NuoModelTextured>();
        model->SetCheckTransparency(options._textureAlphaType == kNuoModelTextureAlpha_Embedded);
        return model;
    }
    else if (options._textured && options._basicMaterialized)
    {
        auto model = std::make_shared<NuoModelMaterialedTextured>();
        model->SetCheckTransparency(true);
        model->SetIgnoreTextureTransparency(options._textureAlphaType == kNuoModelTextureAlpha_Sided);
        return model;
    }
    else if (options._basicMaterialized)
    {
        return std::make_shared<NuoModelMaterialed>();
    }
    else
    {
        return std::shared_ptr<NuoModelBase>();
    }
}



void* NuoModelBase::IndicesPtr()
{
    return _indices.data();
}



size_t NuoModelBase::IndicesLength()
{
    return _indices.size() * sizeof(uint32_t);
}



NuoBox NuoModelBase::GetBoundingBox()
{
    float xMin = 1e9f, xMax = -1e9f;
    float yMin = 1e9f, yMax = -1e9f;
    float zMin = 1e9f, zMax = -1e9f;
    
    for (size_t i = 0; i < GetVerticesNumber(); ++i)
    {
        vector_float4 position = GetPosition(i);
        
        xMin = std::min(xMin, position.x);
        xMax = std::max(xMax, position.x);
        yMin = std::min(yMin, position.y);
        yMax = std::max(yMax, position.y);
        zMin = std::min(zMin, position.z);
        zMax = std::max(zMax, position.z);
    }
    
    return NuoBox { (xMax + xMin) / 2.0f, (yMax + yMin) / 2.0f, (zMax + zMin) / 2.0f,
                    xMax - xMin, yMax - yMin, zMax - zMin };
}



NuoItemSimple::NuoItemSimple() :
    _position(0), _normal(0)
{
}


bool NuoItemSimple::operator == (const NuoItemSimple& i2)
{
    return
        (_position.x == i2._position.x) &&
        (_position.y == i2._position.y) &&
        (_position.z == i2._position.z) &&
        (_normal.x == i2._normal.x) &&
        (_normal.y == i2._normal.y) &&
        (_normal.z == i2._normal.z);
}



NuoModelSimple::NuoModelSimple()
{
}



void NuoModelSimple::AddTexCoord(size_t sourceIndex, const std::vector<float>& texCoordBuffer)
{    
}


void NuoModelSimple::AddMaterial(const NuoMaterial& material)
{
}



void NuoModelSimple::SetTexturePathDiffuse(const std::string texPath)
{
}



std::string NuoModelSimple::GetTexturePathDiffuse()
{
    return std::string();
}


void NuoModelSimple::SetTexturePathOpacity(const std::string texPath)
{
}


std::string NuoModelSimple::GetTexturePathOpacity()
{
    return std::string();
}



bool NuoModelSimple::HasTransparent()
{
    return false;
}




