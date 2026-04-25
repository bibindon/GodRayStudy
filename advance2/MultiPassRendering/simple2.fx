texture g_SceneTexture;
texture g_OcclusionTexture;

sampler g_SceneSampler = sampler_state
{
    Texture = (g_SceneTexture);
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler g_OcclusionSampler = sampler_state
{
    Texture = (g_OcclusionTexture);
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

float2 g_LightScreenPos = float2(0.5f, 0.2f);
float3 g_LightColor = float3(1.0f, 1.0f, 1.0f);

float g_RayLength = 1.0f;
float g_RayIntensity = 0.9f;
float g_OcclusionFalloff = 6.0f;
float g_DebugShowOcclusion = 0.0f;

static const int SAMPLE_COUNT = 200;

struct VS_IN
{
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
};

struct VS_OUT
{
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
};

VS_OUT VS(VS_IN i)
{
    VS_OUT o;
    o.pos = i.pos;
    o.uv = i.uv;
    return o;
}

float4 PS(VS_OUT i) : COLOR
{
    if (g_DebugShowOcclusion > 0.5f)
    {
        float mask = tex2D(g_OcclusionSampler, i.uv).r;
        return float4(mask, mask, mask, 1.0f);
    }

    float2 lightPos = g_LightScreenPos;
    float2 dir = lightPos - i.uv;

    float visibilitySum = 0.0f;
    float validSampleCount = 0.0f;

    [loop]
    for (int s = 0; s < SAMPLE_COUNT; ++s)
    {
        float t = g_RayLength * (float(s) / float(SAMPLE_COUNT - 1));
        float2 sampleUv = i.uv + dir * t;
        if (sampleUv.x >= 0.0f && sampleUv.x <= 1.0f &&
            sampleUv.y >= 0.0f && sampleUv.y <= 1.0f)
        {
            visibilitySum += tex2D(g_OcclusionSampler, sampleUv).r;
            validSampleCount += 1.0f;
        }
    }

    float lightRays = 0.0f;
    if (validSampleCount > 0.0f)
    {
        lightRays = visibilitySum / validSampleCount;
    }

    float occlusion = 1.0f - lightRays;
    lightRays = exp(-g_OcclusionFalloff * occlusion);

    float3 sceneColor = tex2D(g_SceneSampler, i.uv).rgb;
    float3 rayColor = lightRays * g_RayIntensity * g_LightColor;
    return float4(sceneColor + rayColor, 1.0f);
}

technique Technique1
{
    pass P0
    {
        CullMode = NONE;
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
