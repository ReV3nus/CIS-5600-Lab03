Shader "Custom/ToonShader"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (1, 1, 1, 1)
        _HighlightColor ("Highlight Color", Color) = (1, 1, 1, 1)
        _ShadowColor ("Shadow Color", Color) = (1, 1, 1, 1)
        _ShadowMap("Shadow Map", 2D) = "white"
        _Smoothness("Smoothness", Float) = 0.5
    }
    SubShader
    {
        
        Tags { "LightMode" = "UniversalForward"  "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS  : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 objPos : TEXCOORD2;
                float4 shadowCoords : TEXCOORD3;
                float2 uv : TEXCOORD4;
            };

            
            TEXTURE2D(_ShadowMap);
            SAMPLER(sampler_ShadowMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _MainColor;
                half4 _HighlightColor;
                half4 _ShadowColor;
                float4 _ShadowMap_ST;
                float _Smoothness;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);
                VertexNormalInputs normals = GetVertexNormalInputs(IN.normalOS);

                OUT.positionCS = positions.positionCS;
                OUT.positionWS = positions.positionWS;
                OUT.normal = normals.normalWS;

                OUT.shadowCoords = GetShadowCoord(positions);

                OUT.uv = TRANSFORM_TEX(IN.uv, _ShadowMap);

                return OUT;
            }

            half4 GetShadowColor(half shadow, float2 uv)
            {
                half4 tex = SAMPLE_TEXTURE2D(_ShadowMap, sampler_ShadowMap, uv);
                half4 shadowColor = tex * _ShadowColor;
                return shadow * _MainColor + (1-shadow) * shadowColor;
            }
            half4 GetSmoothColor(float NdotL)
            {
                if(NdotL < 0.5) return _MainColor;
                float theta = acos(NdotL) * 180 / 3.1415926;

                float u = smoothstep(15 - _Smoothness * 15, 15 + _Smoothness * 15, theta);

                half4 res = u * _MainColor + (1-u) * _HighlightColor;
                return res;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                Light mainLight = GetMainLight();

                float3 N = normalize(IN.normal);
                float3 L = mainLight.direction;
                
                float NdotL = saturate(dot(N, L));
                
                half shadowAmount = MainLightRealtimeShadow(IN.shadowCoords);

                return shadowAmount < 0.5 ? GetShadowColor(shadowAmount, IN.uv) : GetSmoothColor(NdotL);
            }
            
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
