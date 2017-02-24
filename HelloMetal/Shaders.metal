/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <metal_stdlib>
using namespace metal;

// 1
struct TexturedVertexIn {
  packed_float4 position;
  packed_float4 color;
  packed_float2 texCoord;
  packed_float3 normal;
};

struct TexturedVertexOut {
  float4 position [[position]];
  float3 fragmentPosition;
  float4 color;
  float2 texCoord;
  float3 normal;
};

struct Light {
  packed_float3 color;      // 0 - 2
  float ambientIntensity;          // 3
  packed_float3 direction;  // 4 - 6
  float diffuseIntensity;   // 7
  float shininess;          // 8
  float specularIntensity;  // 9
  
  /*
   _______________________
   |0 1 2 3|4 5 6 7|8 9    |
   -----------------------
   |       |       |       |
   | chunk0| chunk1| chunk2|
   */
};

struct LightedUniforms{
  float4x4 modelMatrix;
  float4x4 projectionMatrix;
  Light light;
};

vertex TexturedVertexOut textured_vertex(
                              const device TexturedVertexIn* vertex_array [[ buffer(0) ]],
                              const device LightedUniforms&  uniforms    [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]]) {
  
  float4x4 mv_Matrix = uniforms.modelMatrix;
  float4x4 proj_Matrix = uniforms.projectionMatrix;
  
  TexturedVertexIn VertexIn = vertex_array[vid];
  
  TexturedVertexOut VertexOut;
  VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position);
  VertexOut.fragmentPosition = (mv_Matrix * float4(VertexIn.position)).xyz;
  VertexOut.color = VertexIn.color;
  // 2
  VertexOut.texCoord = VertexIn.texCoord;
  VertexOut.normal = (mv_Matrix * float4(VertexIn.normal, 0.0)).xyz;
  
  return VertexOut;
}

// 3
fragment float4 textured_fragment(TexturedVertexOut interpolated [[stage_in]],
                               const device LightedUniforms&  uniforms    [[ buffer(1) ]],
                               texture2d<float>  tex2D     [[ texture(0) ]],
                               sampler           sampler2D [[ sampler(0) ]]) {
  
  // Ambient
  Light light = uniforms.light;
  float4 ambientColor = float4(light.color * light.ambientIntensity, 1);
  
  //Diffuse
  float diffuseFactor = max(0.0,dot(interpolated.normal, light.direction)); // 1
  float4 diffuseColor = float4(light.color * light.diffuseIntensity * diffuseFactor ,1.0); // 2
  
  //Specular
  float3 eye = normalize(interpolated.fragmentPosition); //1
  float3 reflection = reflect(light.direction, interpolated.normal); // 2
  float specularFactor = pow(max(0.0, dot(reflection, eye)), light.shininess); //3
  float4 specularColor = float4(light.color * light.specularIntensity * specularFactor ,1.0);//4
  
  // 5
  float4 color = tex2D.sample(sampler2D, interpolated.texCoord);
  return color * (ambientColor + diffuseColor + specularColor);
}

struct ColoredVertexIn{
    packed_float3 position;
    packed_float4 color;
};

struct ColoredVertexOut{
    float4 position [[position]];  //1
    float4 color;
};

struct BasicUniforms{
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};

vertex ColoredVertexOut colored_vertex(                           // 1
                              const device ColoredVertexIn* vertex_array [[ buffer(0) ]],   // 2
                              const device BasicUniforms&  uniforms    [[ buffer(1) ]],           //1
                              unsigned int vid [[ vertex_id ]]) {
    
    float4x4 mv_Matrix = uniforms.modelMatrix;                     //2
    float4x4 proj_Matrix = uniforms.projectionMatrix;
    
    ColoredVertexIn VertexIn = vertex_array[vid];                 // 3
    
    ColoredVertexOut VertexOut;
    VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position,1);
    VertexOut.color = VertexIn.color;                       // 4
    
    return VertexOut;
}

fragment half4 colored_fragment(ColoredVertexOut interpolated [[stage_in]]) {  //1
    return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]); //2
}


///////


struct TextVertexIn
{
    packed_float4 position;
    packed_float2 texCoords;
};

struct TextVertexOut
{
    float4 position [[position]];
    float2 texCoords;
};

struct TextUniforms
{
    float4x4 modelMatrix;
    float4x4 viewProjectionMatrix;
    float4 foregroundColor;
};

vertex TextVertexOut text_vertex(constant TextVertexIn *vertices [[buffer(0)]],
                                      constant TextUniforms &uniforms [[buffer(1)]],
                                      uint vid [[vertex_id]])
{
    TextVertexOut outVert;
    outVert.position = uniforms.viewProjectionMatrix * uniforms.modelMatrix * float4(vertices[vid].position);
    outVert.texCoords = vertices[vid].texCoords;
    return outVert;
}

fragment half4 text_fragment(TextVertexOut vert [[stage_in]],
                              constant TextUniforms &uniforms [[buffer(0)]],
                              sampler samplr [[sampler(0)]],
                              texture2d<float, access::sample> texture [[texture(0)]])
{
    float4 color = uniforms.foregroundColor;
    // Outline of glyph is the isocontour with value 50%
    float edgeDistance = 0.5;
    // Sample the signed-distance field to find distance from this fragment to the glyph outline
    float sampleDistance = texture.sample(samplr, vert.texCoords).r;
    // Use local automatic gradients to find anti-aliased anisotropic edge width, cf. Gustavson 2012
    float edgeWidth = 0.75 * length(float2(dfdx(sampleDistance), dfdy(sampleDistance)));
    // Smooth the glyph edge by interpolating across the boundary in a band with the width determined above
    float insideness = smoothstep(edgeDistance - edgeWidth, edgeDistance + edgeWidth, sampleDistance);
    return half4(color.r, color.g, color.b, insideness);
}

