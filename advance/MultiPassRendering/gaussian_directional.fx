texture texture1;

sampler s0 = sampler_state
{
    Texture = (texture1);
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

float2 g_ScreenSize = float2(1600.0f, 900.0f);
float2 g_BlurDirection = float2(1.0f, 0.0f);
float g_BlurSigma = 3.5f;
float g_BlurExtentPixels = 50.0f;

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

float GaussianWeight(float2 offsetPixels)
{
    float sigma2 = max(g_BlurSigma * g_BlurSigma, 0.0001f);
    return exp(-dot(offsetPixels, offsetPixels) / (2.0f * sigma2));
}

float4 PS(VS_OUT i) : COLOR
{
    const int HALF_KERNEL = 25;

    float2 dir = g_BlurDirection;
    float dirLength = length(dir);
    if (dirLength < 0.0001f)
    {
        dir = float2(1.0f, 0.0f);
    }
    else
    {
        dir /= dirLength;
    }

    float2 perp = float2(-dir.y, dir.x);
    float2 pixelStep = 1.0f / g_ScreenSize;
    float tapSpacingPixels = g_BlurExtentPixels / HALF_KERNEL;

    float3 sum = 0.0f;
    float totalWeight = 0.0f;

    [loop]
    for (int y = -HALF_KERNEL; y <= HALF_KERNEL; ++y)
    {
        [loop]
        for (int x = -HALF_KERNEL; x <= HALF_KERNEL; ++x)
        {
            float2 kernelOffset = float2((float)x, (float)y);
            float2 stretchedOffset = kernelOffset * tapSpacingPixels;
            float2 sampleOffset = (dir * stretchedOffset.x + perp * stretchedOffset.y) * pixelStep;
            float weight = GaussianWeight(stretchedOffset);
            sum += tex2D(s0, i.uv + sampleOffset).rgb * weight;
            totalWeight += weight;
        }
    }

    return float4(sum / max(totalWeight, 0.0001f), 1.0f);
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
