float4x4 g_matWorldViewProj;

void VertexShader1(in  float4 inPosition  : POSITION,
                   out float4 outPosition : POSITION)
{
    outPosition = mul(inPosition, g_matWorldViewProj);
}

void PixelShader1(out float4 outColor : COLOR)
{
    outColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
}

technique Technique1
{
    pass Pass1
    {
        CullMode = NONE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VertexShader1();
        PixelShader = compile ps_3_0 PixelShader1();
    }
}
