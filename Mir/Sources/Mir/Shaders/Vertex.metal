// Vertex.metal
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

#include <metal_stdlib>
#include "../../MirSharedTypes/include/Uniforms.h"
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertexShader(
                              const VertexIn vertexIn [[stage_in]],
                              constant Uniforms &uniforms [[buffer(1)]]
                              ) {
    VertexOut out;
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * vertexIn.position;
    return out;
}
