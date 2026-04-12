// Uniforms.h
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

#ifndef Uniforms_h
#define Uniforms_h

#include <simd/simd.h>

typedef struct {
    simd_float4x4 modelMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 projectionMatrix;
} Uniforms;

#endif /* Uniforms_h */
