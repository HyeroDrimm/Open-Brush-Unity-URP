#include "BrushURP.cginc"

void Vert_float(float4 uv, float3 vertexNormal, float3 position, out float3 vertexPos)
{
    float t, uTileRate, waveIntensity;

    float radius = uv.z;


    t = _Time.z;
    uTileRate = 10;
    waveIntensity = .6;

      // Ensure the t parameter wraps (1.0 becomes 0.0) to avoid cracks at the seam.
    float theta = fmod(uv.y, 1);
    vertexPos = position + pow(1 - (sin(t + uv.x * uTileRate + theta * 10) + 1), 2)
              * vertexNormal.xyz * waveIntensity
              * radius;
}

void Frag_float(UnityTexture2D mainTex, float4 uv, float4 INcolor, float3 worldPos, out float3 Normal, out float3 Emission)
{
    float4 tex = tex2D(mainTex, uv);
    Normal = float3(0, 0, 1);

      // XXX need to convert world normal to tangent space normal somehow...
    float3 worldNormal = normalize(cross(ddy(worldPos), ddx(worldPos)));
    Normal = -cross(cross(Normal, worldNormal), worldNormal);
    Normal = normalize(Normal);

      // Add a fake "disco ball" hot spot
    float fakeLight = pow(abs(dot(worldNormal, float3(0, 1, 0))), 100);
    Emission = INcolor.rgb * fakeLight * 200;
}

void ARVert_float(float4 uv, float3 vertexNormal, float3 position, out float3 vertexPos)
{
    float t, uTileRate, waveIntensity;

    float radius = uv.z;

    t = _BeatOutputAccum.z * 5;
    uTileRate = 5;
    waveIntensity = (_PeakBandLevels.y * .8 + .5);
    float waveform = tex2Dlod(_WaveFormTex, float4(uv.x * 2, 0, 0, 0)).b - .5f;
    vertexPos = position + waveform * vertexNormal * .2;

      // Ensure the t parameter wraps (1.0 becomes 0.0) to avoid cracks at the seam.
    float theta = fmod(uv.y, 1);
    vertexPos += pow(1 - (sin(t + uv.x * uTileRate + theta * 10) + 1), 2)
              * vertexNormal.xyz * waveIntensity
              * radius;
}
