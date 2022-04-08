#include "BrushURP.cginc"

float3 SrgbToNative3(float3 color)
{
    float4 result;
    SrgbToNative_float(float4(color, 1), result);
    return result.rgb;
}

void NonAudioReaciveFragment_float(float4 INcolor, float4 uv, out float3 Albedo, out float3 Specular, out float Smoothness, out float3 Emission)
{
    float envelope = sin(fmod(uv.x * 2, 1.0f) * 3.14159);
    float lights = envelope < .1 ? 1 : 0;
    float border = abs(envelope - .1) < .01 ? 0 : 1;
    Specular = .3 - lights * .15;
    Smoothness = .3 + lights * .3;

    float t;

    t = _Time.w;

    if (lights)
    {
        int colorindex = fmod(uv.x * 2 + 0.5, 3);
        if (colorindex == 0) 
            INcolor.rgb = INcolor.rgb * float3(.2, .2, 1);
        else if (colorindex == 1) 
            INcolor.rgb = INcolor.rgb * float3(1, .2, .2);
        else
            INcolor.rgb = INcolor.rgb * float3(.2, 1, .2);

        float lightindex = fmod(uv.x * 2 + .5, 7);
        float timeindex = fmod(t, 7);
        float delta = abs(lightindex - timeindex);
        float on = 1 - saturate(delta * 1.5);
        bloomColor_float(INcolor * on, .7, INcolor);
    }

    Albedo = (1 - lights) * INcolor.rgb * .2;
    Albedo *= border;
    Specular *= border;

    Emission = lights * INcolor.rgb;

    Albedo = SrgbToNative3(Albedo);
    Emission = SrgbToNative3(Emission);
    Specular = SrgbToNative3(Specular);
}

void AudioReaciveFragment_float(float4 INcolor, float4 uv, out float3 Albedo, out float3 Specular, out float Smoothness, out float3 Emission)
{
    float envelope = sin(fmod(uv.x * 2, 1.0f) * 3.14159);
    float lights = envelope < .1 ? 1 : 0;
    float border = abs(envelope - .1) < .01 ? 0 : 1;
    Specular = .3 - lights * .15;
    Smoothness = .3 + lights * .3;

    float t;
    t = _BeatOutputAccum.x * 10;


    if (lights)
    {
        int colorindex = fmod(uv.x * 2 + 0.5, 3);
        if (colorindex == 0) 
            INcolor.rgb = INcolor.rgb * float3(.2, .2, 1);
        else if (colorindex == 1) 
            INcolor.rgb = INcolor.rgb * float3(1, .2, .2);
        else
            INcolor.rgb = INcolor.rgb * float3(.2, 1, .2);

        float lightindex = fmod(uv.x * 2 + .5, 7);
        float timeindex = fmod(t, 7);
        float delta = abs(lightindex - timeindex);
        float on = 1 - saturate(delta * 1.5);
        bloomColor_float(INcolor * on, .7, INcolor);
    }

    Albedo = (1 - lights) * INcolor.rgb * .2;
    Albedo *= border;
    Specular *= border;

    INcolor.rgb = INcolor.rgb * .25 + INcolor.rgb * _BeatOutput.x * .75;
    Emission = lights * INcolor.rgb;

    Albedo = SrgbToNative3(Albedo);
    Emission = SrgbToNative3(Emission);
    Specular = SrgbToNative3(Specular);
}


void Vert_float(float4 uv, float3 normal, float3 position, out float3 vertexPos)
{
    float radius = uv.z;

    float t;
    float envelope = sin(fmod(uv.x * 2, 1.0f) * 3.14159);
    float lights = envelope < .15 ? 1 : 0;

    radius *= 0.9;
    vertexPos = position + normal * lights * radius;
}