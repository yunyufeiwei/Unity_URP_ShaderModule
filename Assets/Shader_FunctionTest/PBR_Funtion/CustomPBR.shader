Shader "Unlit/CustomPBR"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _Metallic("Metallic",Float) = 0
        _Smoothness("Smoothness",Float) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float2 lightUV     : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 viewDir      : TEXCOORD3;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH,4);
            };

            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float _Smoothness;
                float _Metallic;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                VertexPositionInputs vertexInput;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS =TransformObjectToWorld(v.positionOS.xyz);
                
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewDir = GetWorldSpaceNormalizeViewDir(o.positionWS);    //这个函数已经对相机位置与物体位置进行了归一化
                
                 OUTPUT_LIGHTMAP_UV(v.lightUV,unity_LightmapST,o.lightmapUV); //输出o.lightmapUV
                 OUTPUT_SH(o.normalWS.xyz,o.vertexSH);  //输出o.vertexSH
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor = 0;
                
                 InputData inputData = (InputData)0;
                 inputData.positionWS = i.positionWS;
                 inputData.normalWS = normalize(i.normalWS);
                 inputData.viewDirectionWS = normalize(i.viewDir);
                 inputData.bakedGI = SAMPLE_GI(i.lightmapUV,i.vertexSH,i.normalWS);
                
                 SurfaceData surfaceData = (SurfaceData)0;
                 surfaceData.albedo = _Color;
                 surfaceData.specular = 0;
                 surfaceData.metallic = _Metallic;
                 surfaceData.smoothness = _Smoothness;
                 surfaceData.normalTS = 0;
                 surfaceData.emission = 0;
                 surfaceData.occlusion = 1.0;
                 surfaceData.alpha = 1;
                 surfaceData.clearCoatMask = 0;
                 surfaceData.clearCoatSmoothness = 0;
                
                FinalColor = UniversalFragmentPBR(inputData,surfaceData);   
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
