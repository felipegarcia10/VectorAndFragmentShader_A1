Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)
        _AmbientColor("Ambient Color", Color) = (0.1,0.1,0.2,1)

        [Header(Cel Bands)]
        _ShadowColor("Shadow Color", Color) = (0.2,0.2,0.3,1)
        _MidColor("Mid Color", Color) = (0.6,0.6,0.7,1)
        _HighlightColor("Highlight Color", Color) = (1.0,1.0,1.0,1)
        _BandThreshold1 ("Shadow Threshold", Range(0,1)) = 0.3
        _BandThreshold2 ("Mid Threshold", Range(0,1)) = 0.6

        [Header(Rim Light)]
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimPower("Rim Power", Range(0.1, 10)) = 3.0
        _RimStrenth("Rim Strength", Range(0,1)) = 0.5

        [Header(Outline)]
        _OutlineColor("Outline Color", Color) = (0.0,0.0,0.3,1)
        _OutlineWidth("Outline Width", Range(0, 0.3)) = 0.05

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "Outline"
            Tags { "LightMode" = "Always" }
            Cull Front
            ZWrite On

            CGPROGRAM
            #pragma vertex vert_outline
            #pragma fragment frag_outline
            #include "UnityCG.cginc"

            float4 _OutlineColor;
            float _OutlineWidth;

            struct appdata_outline
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
            };

            struct v2f_outline
            {
                float4 pos : SV_POSITION;
            };

            v2f_outline vert_outline (appdata_outline v)
            {
                v2f_outline o;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                worldPos += worldNormal * _OutlineWidth;
                o.pos = UnityWorldToClipPos(worldPos);
                return o;
            }

            fixed4 frag_outline(v2f_outline i) : SV_Target
            {
                return _OutlineColor;
            }

            ENDCG
        }

        Pass
        {
            Name "CelShader"
            Tags { "LightMode" = "ForwardBase" }
            Cull Back
            ZWrite On
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
                        
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 pos : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 _Color;
            fixed4 _AmbientColor;
            fixed4 _ShadowColor;
            fixed4 _MidColor;
            fixed4 _HighlightColor;
            float _BandThreshold1;
            float _BandThreshold2;
            float _RimPower;
            float4 _RimColor;
            float _RimStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.pos).xyz;
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 CelColor(float diffuse)
            {
                if(diffuse < _BandThreshold1) return _ShadowColor;
                if(diffuse < _BandThreshold2) return _MidColor;
                return _HighlightColor;

            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 albedo = tex2D(_MainTex, i.uv) * _Color;

                float3 N = normalize(i.worldNormal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                //diffuse
                float NdotL = saturate(dot(N,L));

                float shadow = SHADOW_ATTENUATION(i);

                float litAmount = NdotL * (shadow * 0.8 + 0.2);

                fixed4 celColor = CelColor(litAmount);

                float rim = 1.0 - saturate(dot(V,N));
                rim = pow(rim, _RimPower);
                fixed4 rimLight = _RimColor * rim * _RimStrength;

                fixed4 col = albedo * (celColor + _AmbientColor) + rimLight;
                col.a = albedo.a;
                
                return col;
            }
            ENDCG
        }
    }
}
