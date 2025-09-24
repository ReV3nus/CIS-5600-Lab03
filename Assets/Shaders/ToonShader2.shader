Shader "Custom/ToonShader2"
{

    Properties
    { 
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;    
            CBUFFER_END

            struct appdata
            {
                float4 position  : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float4 vertex  : SV_POSITION;
                float3 normal : TEXCOORD1;
                float4 objPos : TEXCOORD2;
                float4 shadowCoords : TEXCOORD3;
            };

            v2f vert(appdata v)
            {
                v2f o;

                o.vertex = TransformObjectToHClip(v.position.xyz);

                // Get the VertexPositionInputs for the vertex position  
                VertexPositionInputs positions = GetVertexPositionInputs(v.position.xyz);
                VertexNormalInputs normals = GetVertexNormalInputs(v.normal);

                // Convert the vertex position to a position on the shadow map
                float4 shadowCoordinates = GetShadowCoord(positions);

                // Pass the shadow coordinates to the fragment shader
                o.shadowCoords = shadowCoordinates;


                o.objPos = v.position;
                o.worldPos = positions.positionWS;
                o.normal = normals.normalWS;

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {               
                float4 col = _BaseColor;
                half shadowAmount = MainLightRealtimeShadow(i.shadowCoords);

                Light mainLight = GetMainLight();

                col *= shadowAmount < 1 ? 0.3 : 1.0;
                
                return col;
            }
            
            ENDHLSL
        }
    }
}
