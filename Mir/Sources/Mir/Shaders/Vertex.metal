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
    float3 position;
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertexShader(
                              uint vertexID [[vertex_id]],
                              constant float3 *vertices [[buffer(0)]],
                              constant Uniforms &uniforms [[buffer(1)]]
                              ) {
    VertexOut out;
    float4 position = float4(vertices[vertexID], 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * position;
    return out;
}
