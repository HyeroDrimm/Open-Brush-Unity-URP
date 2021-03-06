#include "BrushURP.cginc"

// Amplitude reflection coefficient (s-polarized)
float rs(float n1, float n2, float cosI, float cosT)
{
    return (n1 * cosI - n2 * cosT) / (n1 * cosI + n2 * cosT);
}

      // Amplitude reflection coefficient (p-polarized)
float rp(float n1, float n2, float cosI, float cosT)
{
    return (n2 * cosI - n1 * cosT) / (n1 * cosT + n2 * cosI);
}

      // Amplitude transmission coefficient (s-polarized)
float ts(float n1, float n2, float cosI, float cosT)
{
    return 2 * n1 * cosI / (n1 * cosI + n2 * cosT);
}

      // Amplitude transmission coefficient (p-polarized)
float tp(float n1, float n2, float cosI, float cosT)
{
    return 2 * n1 * cosI / (n1 * cosT + n2 * cosI);
}

      // cosI is the cosine of the incident angle, that is, cos0 = dot(view angle, normal)
      // lambda is the wavelength of the incident light (e.g. lambda = 510 for green)
      // http://www.gamedev.net/page/resources/_/technical/graphics-programming-and-theory/thin-film-interference-for-computer-graphics-r2962
float thinFilmReflectance(float cos0, float lambda, float thickness, float n0, float n1, float n2)
{
    const float pi = 3.1415926536;

        // Phase change terms.
    const float d10 = lerp(pi, 0, n1 > n0);
    const float d12 = lerp(pi, 0, n1 > n2);
    const float delta = d10 + d12;

        // Cosine of the reflected angle.
    const float sin1 = pow(n0 / n1, 2) * (1 - pow(cos0, 2));

        // Total internal reflection.
    if (sin1 > 1)
        return 1.0;
    const float cos1 = sqrt(1 - sin1);

        // Cosine of the final transmitted angle, i.e. cos(theta_2)
        // This angle is for the Fresnel term at the bottom interface.
    const float sin2 = pow(n0 / n2, 2) * (1 - pow(cos0, 2));

        // Total internal reflection.
    if (sin2 > 1)
        return 1.0;

    const float cos2 = sqrt(1 - sin2);

        // Reflection transmission amplitude Fresnel coefficients.
        // rho_10 * rho_12 (s-polarized)
    const float alpha_s = rs(n1, n0, cos1, cos0) * rs(n1, n2, cos1, cos2);
        // rho_10 * rho_12 (p-polarized)
    const float alpha_p = rp(n1, n0, cos1, cos0) * rp(n1, n2, cos1, cos2);

        // tau_01 * tau_12 (s-polarized)
    const float beta_s = ts(n0, n1, cos0, cos1) * ts(n1, n2, cos1, cos2);
        // tau_01 * tau_12 (p-polarized)
    const float beta_p = tp(n0, n1, cos0, cos1) * tp(n1, n2, cos1, cos2);

        // Compute the phase term (phi).
    const float phi = (2 * pi / lambda) * (2 * n1 * thickness * cos1) + delta;

        // Evaluate the transmitted intensity for the two possible polarizations.
    const float ts = pow(beta_s, 2) / (pow(alpha_s, 2) - 2 * alpha_s * cos(phi) + 1);
    const float tp = pow(beta_p, 2) / (pow(alpha_p, 2) - 2 * alpha_p * cos(phi) + 1);

        // Take into account conservation of energy for transmission.
    const float beamRatio = (n2 * cos2) / (n0 * cos0);

        // Calculate the average transmitted intensity (polarization distribution of the
        // light source here. If unknown, 50%/50% average is generally used)
    const float t = beamRatio * (ts + tp) / 2;

        // Derive the reflected intensity.
    return 1 - t;
}

float3 GetDiffraction(float3 thickTex, float3 I, float3 N)
{
    const float thicknessMin = 250;
    const float thicknessMax = 400;
    const float nmedium = 1;
    const float nfilm = 1.3;
    const float ninternal = 1;
        
    const float cos0 = abs(dot(I, N));

        //float3 thickTex = texture(thickness, u, v);
    const float t = (thickTex[0] + thickTex[1] + thickTex[2]) / 3.0;
    const float thick = thicknessMin * (1.0 - t) + thicknessMax * t;

    const float red = thinFilmReflectance(cos0, 650, thick, nmedium, nfilm, ninternal);
    const float green = thinFilmReflectance(cos0, 510, thick, nmedium, nfilm, ninternal);
    const float blue = thinFilmReflectance(cos0, 475, thick, nmedium, nfilm, ninternal);

    return float3(red, green, blue);
}

void Frag_float(UnityTexture2D mainTex, float3 viewDirection, float3 worldNormal, float3 normalVector, float3 worldPos, float4 INcolor, out float3 Albedo, out float3 Specular, out float Smoothness, out float3 Emission)
{
    Smoothness = .8;
    Albedo = INcolor * .2;
    
        // Calculate rim
    half rim = 1.0 - abs(dot(normalize(viewDirection), worldNormal));
    rim *= 1 - pow(rim, 5);
        
    const float3 I = (_WorldSpaceCameraPos - worldPos);
    rim = lerp(rim, 150,
              1 - saturate(abs(dot(normalize(I), worldNormal)) / .1));

    float3 diffraction = tex2D(mainTex, half2(rim + _Time.x * .3 + normalVector.x, rim + normalVector.y)).xyz;
    diffraction = GetDiffraction(diffraction, normalVector, normalize(viewDirection));

    Emission = rim * INcolor.xyz * diffraction * .5 + rim * diffraction * .25;
    
    float4 nativeINcolor;
    SrgbToNative_float(INcolor, nativeINcolor);
    Specular = nativeINcolor.xyz * clamp(diffraction, .0, 1);
}