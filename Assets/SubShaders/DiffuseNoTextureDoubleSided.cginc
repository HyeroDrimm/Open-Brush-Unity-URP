void Vert_float(float3 objPos, float4 uv0, float4 uv1, out float3 vertexPos)
{
    float envelope = sin(uv0.x * 3.14159);
    float widthMultiplier = 1 - envelope;
    vertexPos = objPos - uv1.xyz * widthMultiplier;
}