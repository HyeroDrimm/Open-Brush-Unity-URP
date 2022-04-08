

void NonAudioReaciveTexColor_float(float4 tex, float2 uv, out float4 OUT)
{
    tex.rgb = float3(1, 0, 0) * (sin(tex.r * 2 + _Time.z * 0.5 - uv.x) + 1) * 2;
    tex.rgb += float3(0, 1, 0) * (sin(tex.r * 3.3 + _Time.z * 1 - uv.x) + 1) * 2;
    tex.rgb += float3(0, 0, 1) * (sin(tex.r * 4.66 + _Time.z * 0.25 - uv.x) + 1) * 2;

    OUT = tex;
}
