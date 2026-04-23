// Fragment.metal
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

#include <metal_stdlib>
#include "VertexOut.h"
using namespace metal;

fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    float3 lightDir = normalize(float3(1.0, 1.0, 1.0));
    float diffuse = max(0.0, dot(normalize(in.normal), lightDir));
    float intensity = 0.15 + diffuse;
    float3 baseColor = float3(0.2, 0.6, 0.3);
    return float4(baseColor * intensity, 1.0);
}
