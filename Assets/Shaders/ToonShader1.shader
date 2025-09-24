Shader "Custom/ToonShader1"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float4 objPos : TEXCOORD2;
            };

            float4 _Color;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.objPos = v.vertex;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                float4 col = _Color;

                float3 L = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.worldPos.xyz, _WorldSpaceLightPos0.w));
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.vertex.xyz);
                float3 H = Unity_SafeNormalize(L + V);
                float3 N = i.normal;

                float NdotL = saturate( dot( N,L ));
                float NdotH = saturate( dot( N,H ));
                float NdotV = saturate( dot( N,V ));
                float VdotH = saturate( dot( V,H ));
                float LdotH = saturate( dot( L,H ));

                col *= NdotL > 0.9 ? 2.0 : 1.0;
                //col = float4(i.objPos.xyz, 1.0);
                //return float4(col, 1);
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
