texture g_SourceTexture;

sampler g_SourceSampler = sampler_state
{
    Texture = (g_SourceTexture);
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

float2 g_TexelSize = float2(1.0f / 1600.0f, 1.0f / 900.0f);
float2 g_BlurDirection = float2(1.0f / 1600.0f, 0.0f);

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
    static const float w[11] =
    {
        0.11987063f,
        0.11611920f,
        0.10579134f,
        0.09048808f,
        0.07270922f,
        0.05488380f,
        0.03890252f,
        0.02593552f,
        0.01624702f,
        0.00957265f,
        0.00530491f
    };

    float sum = tex2D(g_SourceSampler, i.uv).r * w[0];

    [unroll]
    for (int k = 1; k <= 10; ++k)
    {
        float2 offset = g_BlurDirection * float(k);
        sum += tex2D(g_SourceSampler, i.uv + offset).r * w[k];
        sum += tex2D(g_SourceSampler, i.uv - offset).r * w[k];
    }

    return float4(sum, sum, sum, 1.0f);
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
