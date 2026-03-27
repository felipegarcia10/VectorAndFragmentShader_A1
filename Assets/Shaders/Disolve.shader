Shader "Unlit/Disolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _DissolveAmount ("Dissolve Amount", Range(0,1)) = 0.0
        _EdgeWidth ("Edge Width", Range(0,0.2)) = 0.05
        _EdgeColor ("Edge Color", Color) = (1,0.4,0,1)
        _EdgeEmission ("Edge Emission", Range(0,5)) = 2.0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float2 uvNoise: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            float _DissolveAmount;

            float _EdgeWidth;
            float _EdgeEmission;
            float4 _EdgeColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uvNoise = TRANSFORM_TEX(v.uv, _NoiseTex);                
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {                
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float noiseVal = tex2D(_NoiseTex, i.uvNoise).r;

                float dissolveThreshold = ((noiseVal - _DissolveAmount) * (1.0 + _EdgeWidth)) + _EdgeWidth;
                clip(dissolveThreshold);

                float edgeFactor = 1.0 - smoothstep(0.0, _EdgeWidth, dissolveThreshold);
                float4 edgeColor = _EdgeColor * _EdgeEmission;
                float4 finalColor = lerp(col, edgeColor, edgeFactor);
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return finalColor;
                
            
            }
            ENDCG
        }
    }
}
