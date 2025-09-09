// simple2.fx�i�u�������j

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

// ��ʏ�̌����ʒu�i0..1�j�B��F���z�̌����Ă���ʒu
float2 g_LightScreenPos = float2(0.8f, 0.2f);

// �����p�p�����[�^
float g_Exposure = 0.9f; // �S�̂̋���
float g_Decay = 0.95f; // �����i�T���v�����i�ނ��ƂɎ�߂�j
float g_Density = 0.97f; // �T���v���Ԋu�X�P�[��
float g_Weight = 0.35f; // �e�T���v���̊�^�����l
float g_Threshold = 0.7f; // ���邳臒l�ibright-pass�j

float g_bVisible = 0.f;

struct VS_IN
{
    float4 pos : POSITION; // �N���b�v��ԁi-1..1, w=1�j
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
    // �P�x
    float l = dot(c, float3(0.299, 0.587, 0.114));
    // 臒l���Â��Ƃ���͗}���A���邢���͋���
    float w = saturate((l - g_Threshold) * 10.0f);
    return c * w;
}

float4 PS(VS_OUT i) : COLOR
{
    // ���W�A���u���[�iGod Rays�j
    const int NUM_SAMPLES = 64;

    float2 delta = (g_LightScreenPos - i.uv) * (g_Density / NUM_SAMPLES);

    float2 coord = i.uv;

    float illuminationDecay = 1.0f;
    float3 sum = 0.0f;

    // �u���[�o�H����T���v�����Ē~��
    [unroll]
    for (int s = 0; s < NUM_SAMPLES; ++s)
    {
        coord += delta;
        float3 c = tex2D(s0, coord).rgb;
        c = BrightPass(c); // ���邢��������ʂ�
        c *= illuminationDecay * g_Weight; // �������Ȃ��瑫��
        sum += c;
        illuminationDecay *= g_Decay;
    }

    // ���̃V�[���F + �S�b�h���C�����Z
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
