Shader "Unlit/WaterShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DetailTex ("Detail Tex", 2D) = "white" {}
        _Color ("Water Tint", Color) = (0.1, 0.4, 0.7, 0.75)

        [Header(Wave Settings)]
        _WaveAmplitude ("Wave Height", Range(0,1)) = 0.1
        _WaveFrequency ("Wave Frequency", Range(0,10)) = 2.0
        _WaveSpeed ("Wave Speed", Range(0,5)) = 1.0
    
        [Header (UV Scroll)]
        _ScrollSpeedX ("Scroll Speed X", Range(-1, 1)) = 0.05
        _ScrollSpeedY ("Scroll Speed Y", Range(-1, 1)) = 0.08
        _OctaveScrollX ("OctaveScrollX", Range(-1, 1)) = -0.03
        _OctaveScrollY ("OctavescrollY", Range(-1, 1)) = 0.06
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        LOD 100

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
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float2 uvDetail : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailTex;
            float4 _DetailTex_ST;
            float4 _Color;

            float _WaveAmplitude;
            float _WaveFrequency;
            float _WaveSpeed;
            float _ScrollSpeedX;
            float _ScrollSpeedY;

            v2f vert (appdata v)
            {
                v2f o;

                float wavePhase = (v.vertex.x + v.vertex.z) * _WaveFrequency;
                float waveTime = _Time.y * _WaveSpeed;

                float wave1 = sin(wavePhase + waveTime) * _WaveAmplitude;
                float wave2 = sin(wavePhase * 0.7 + waveTime * 1.4) * _WaveAmplitude * 0.5;
                float totalWave = wave1 + wave2;

                v.vertex.y += totalWave;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 waterTex = tex2D(_MainTex, i.uv);

                float4 combined = waterTex * _Color;
                // apply fog

                combined.a = _Color.a;


                return combined;
            }
            ENDCG
        }
    }
}
