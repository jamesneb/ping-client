// Shaders.metal

#include <metal_stdlib>
using namespace metal;

// This is the vertex shader
struct VertexIn {
    float4 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

// Basic transformation of vertex positions
vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = in.position;  // Pass through the position as is
    out.color = in.color;        // Pass the color through as is
    return out;
}

// Simple fragment shader
fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;  // Return the color passed from the vertex shader
}

