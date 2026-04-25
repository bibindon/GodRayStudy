// simple2.fx（置き換え）

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

// 画面上の光源位置（0..1）。例：太陽の見えている位置
float2 g_LightScreenPos = float2(0.8f, 0.2f);

// 調整用パラメータ
float g_Exposure = 0.9f; // 全体の強さ
float g_Decay = 0.95f; // 減衰（サンプルが進むごとに弱める）
float g_Density = 0.97f; // サンプル間隔スケール
float g_Weight = 0.35f; // 各サンプルの寄与初期値
float g_Threshold = 0.7f; // 明るさ閾値（bright-pass）

float g_bVisible = 0.f;

struct VS_IN
{
    float4 pos : POSITION; // クリップ空間（-1..1, w=1）
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

float3 BrightPass(float3 c)
{
    // 輝度
    float l = dot(c, float3(0.299, 0.587, 0.114));
    // 閾値より暗いところは抑制、明るい所は強調
    float w = saturate((l - g_Threshold) * 10.0f);
    return c * w;
}

float4 PS(VS_OUT i) : COLOR
{
    // ラジアルブラー（God Rays）
    const int NUM_SAMPLES = 64;

    float2 delta = (g_LightScreenPos - i.uv) * (g_Density / NUM_SAMPLES);

    float2 coord = i.uv;

    float illuminationDecay = 1.0f;
    float3 sum = 0.0f;

    // ブラー経路上をサンプルして蓄積
    [unroll]
    for (int s = 0; s < NUM_SAMPLES; ++s)
    {
        coord += delta;
        float3 c = tex2D(s0, coord).rgb;
        c = BrightPass(c); // 明るい所だけを通す
        c *= illuminationDecay * g_Weight; // 減衰しながら足す
        sum += c;
        illuminationDecay *= g_Decay;
    }

    // 元のシーン色 + ゴッドレイを加算
    float3 scene = tex2D(s0, i.uv).rgb;
    float3 godrays = sum * g_Exposure;

    godrays *= g_bVisible;

    return float4(scene + godrays, 1.0f);
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
