#pragma once
#ifndef BRUSH_URP
#define BRUSH_URP

// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// -*- c -*-

// Canvas transform.
uniform float4x4 xf_CS;
// Inverse canvas transform.
uniform float4x4 xf_I_CS;

// Unity only guarantees signed 2.8 for fixed4.
// In practice, 2*exp(_EmissionGain * 10) = 180, so we need to use float4
void bloomColor_float(float4 color, float gain, out float4 OUT)
{
  // Guarantee that there's at least a little bit of all 3 channels.
  // This makes fully-saturated strokes (which only have 2 non-zero
  // color channels) eventually clip to white rather than to a secondary.
    float cmin = length(color.rgb) * .05;
    color.rgb = max(color.rgb, float3(cmin, cmin, cmin));
  // If we try to remove this pow() from .a, it brightens up
  // pressure-sensitive strokes; looks better as-is.
    color = pow(color, 2.2);
    color.rgb *= 2 * exp(gain * 10);
    OUT = color;
}

// Used by various shaders to animate selection outlines
// Needs to be visible even when the color is black
void GetAnimatedSelectionColor_float(float4 color, out float4 OUT)
{
    OUT = color + sin(_Time.w * 2) * .1 + .2f;
}


//
// Common for Music Reactive Brushes
//

sampler2D _WaveFormTex;
sampler2D _FFTTex;
uniform float4 _BeatOutputAccum;
uniform float4 _BeatOutput;
uniform float4 _AudioVolume;
uniform float4 _PeakBandLevels;

// returns a random value seeded by color between 0 and 2 pi
void randomizeByColor_float(float4 color, out float OUT)
{
    float val = (3 * color.r + 2 * color.g + color.b) * 1000;
    val = 2 * PI * fmod(val, 1);
    OUT = val;
}

void randomNormal_float(float3 color, out float3 OUT)
{
    float noiseX = frac(sin(color.x)) * 46336.23745f;
    float noiseY = frac(sin(color.y)) * 34748.34744f;
    float noiseZ = frac(sin(color.z)) * 59998.47362f;
    OUT = normalize(float3(noiseX, noiseY, noiseZ));
}

void musicReactiveColor_float(float4 color, float beat, out float4 OUT)
{
    float randomOffset;
    randomizeByColor_float(color, randomOffset);
    color.xyz = color.xyz * .5 + color.xyz * saturate(sin(beat * 3.14159 + randomOffset));
    OUT = color;
}

void musicReactiveAnimationWorldSpace_float(float4 worldPos, float4 color, float beat, float t, out float4 OUT)
{
    float intensity = .15;
    float randomizeByColor;
    randomizeByColor_float(color, randomizeByColor);
    float randomOffset = 2 * PI * randomizeByColor + _Time.w + worldPos.z;
  // the first sin function makes the start and end points of the UV's (0:1) have zero modulation.
  // The second sin term causes vibration along the stroke like a plucked guitar string - frequency defined by color
    float3 randomNormal;
    randomNormal_float(color.rgb, randomNormal);
    worldPos.xyz += randomNormal * beat * sin(t * 3.14159) * sin(randomOffset) * intensity;
    OUT = worldPos;
}

void musicReactiveAnimation_float(float4 vertex, float4 color, float beat, float t, out float4 OUT)
{
    float4 worldPos = mul(unity_ObjectToWorld, vertex);
    float4 musicReactiveAnimationWorldSpace;
    musicReactiveAnimationWorldSpace_float(worldPos, color, beat, t, musicReactiveAnimationWorldSpace);
    OUT = mul(unity_WorldToObject, musicReactiveAnimationWorldSpace);
}

void ParticleVertexToWorld_float(float4 vertex, out float4 OUT)
{
    OUT = vertex;
}

//
// For Toolkit support
//

void SrgbToLinear_float(float4 color, out float4 OUT)
{
  // Approximation http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
    float3 sRGB = color.rgb;
    color.rgb = sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
    OUT = color;
}

void SrgbToLinear_Large_float(float4 color, out float4 OUT)
{
    float4 linearColor;
    SrgbToLinear_float(color, linearColor);
    color.r = color.r < 1.0 ? linearColor.r : color.r;
    color.g = color.g < 1.0 ? linearColor.g : color.g;
    color.b = color.b < 1.0 ? linearColor.b : color.b;
    OUT = color;
}

void LinearToSrgb_float(float4 color, out float4 OUT)
{
  // Approximation http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
    float3 linearColor = color.rgb;
    float3 S1 = sqrt(linearColor);
    float3 S2 = sqrt(S1);
    float3 S3 = sqrt(S2);
    color.rgb = 0.662002687 * S1 + 0.684122060 * S2 - 0.323583601 * S3 - 0.0225411470 * linearColor;
    OUT = color;
}

// TB mesh colors are sRGB. TBT mesh colors are linear.
void TbVertToSrgb_float(float4 color, out float4 OUT)
{
    LinearToSrgb_float(color, OUT);
}
void TbVertToLinear_float(float4 color, out float4 OUT)
{
    OUT = color;
}

// Conversions to and from native colorspace.
// Note that SrgbToLinear_Large only converts to linear in the 0:1 range
// because Linear HDR values don't work with the Tilt Brush bloom filter

void SrgbToNative_float(float4 color, out float4 OUT)
{
#ifdef TBT_LINEAR_TARGET
    OUT = color;
#else
    SrgbToLinear_Large_float(color, OUT);
#endif
}
void TbVertToNative_float(float4 color, out float4 OUT)
{
#ifdef TBT_LINEAR_TARGET
    TbVertToSrgb_float(color, OUT);
#else
    TbVertToLinear_float(color, OUT);
#endif
}
void NativeToSrgb_float(float4 color, out float4 OUT)
{
#ifdef TBT_LINEAR_TARGET
    OUT = color;
#else
    LinearToSrgb_float(color, OUT);
#endif
}

// TBT is in meters, TB is in decimeters.
#define kDecimetersToWorldUnits 0.1

#endif