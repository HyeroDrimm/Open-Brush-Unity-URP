#include "BrushURP.cginc"

float3 SrgbToNative3(float3 color)
{
    float4 result;
    SrgbToNative_float(float4(color, 1), result);
    return result.rgb;
}

void Frag_float(float4 uv, float3 viewDir, float4 INcolor, float emissionGain, float3 worldNormal, out float Smoothness, out float3 Specular, out float3 Emission)
{
    Smoothness = .8;
    Specular = .05;
    float audioMultiplier = 1;

    uv.x -= _Time.x * 15;
    uv.x = fmod(abs(uv.x), 1);
    float neon = saturate(pow(10 * saturate(.2 - uv.x), 5) * audioMultiplier);
    
    float4 bloom;
    bloomColor_float(INcolor, emissionGain, bloom);

    half rim = 1.0 - saturate(dot(normalize(viewDir), worldNormal));
    bloom *= pow(1 - rim, 5);
    
    
    Emission = SrgbToNative3(bloom.xyz * neon);
}

void ARFrag_float(float4 uv, float3 viewDir, float4 INcolor, float emissionGain, float3 worldNormal, out float Smoothness, out float3 Specular, out float3 Emission)
{
    Smoothness = .8;
    Specular = .05;
    float audioMultiplier = 1;
    
    audioMultiplier += audioMultiplier * _BeatOutput.x;
    uv.x -= _BeatOutputAccum.z;
    INcolor += INcolor * _BeatOutput.w * .25;

    uv.x = fmod(abs(uv.x), 1);
    float neon = saturate(pow(10 * saturate(.2 - uv.x), 5) * audioMultiplier);
    
    float4 bloom;
    bloomColor_float(INcolor, emissionGain, bloom);

    half rim = 1.0 - saturate(dot(normalize(viewDir), worldNormal));
    bloom *= pow(1 - rim, 5);
    
    
    Emission = SrgbToNative3(bloom.xyz * neon);
}