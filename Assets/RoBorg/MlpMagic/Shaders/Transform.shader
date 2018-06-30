// Add distortion to the magic glow
Shader "Hidden/MlpMagic/Transform"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}

		_Speed("Speed", Float) = 15
		_Frequency("Frequency", Float) = 50
		_Amplitude("Amplitude", Float) = 0.005
	}

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				
				return o;
			}

			sampler2D _MainTex;
			float _Speed;
			float _Frequency;
			float _Amplitude;

			fixed4 frag(v2f i) : SV_Target
			{
				// Distort the x and y coordinates sinusoidally
				// Use 1.01 and 0.99 so they're not perfectly in sync
				i.uv.x += sin(_Time.y * _Speed * 1.01 + i.uv.y * _Frequency * 0.99) * _Amplitude;
				i.uv.y += sin(_Time.y * _Speed * 0.99 + i.uv.x * _Frequency * 1.01) * _Amplitude;

				return tex2D(_MainTex, i.uv);
			}

			ENDCG
		}
	}
}
