// Composite the magic texture on top of the scene
Shader "Hidden/MlpMagic/Composite"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_MagicTex("Texture", 2D) = "white" {}
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
			sampler2D _MagicTex;

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 magic = tex2D(_MagicTex, i.uv);
				fixed4 main = tex2D(_MainTex, i.uv);
				
				float blend = magic.a;
				magic.a = 1;
				main.a = 1;
				
				// return main + (main * magic * blend); // Multiply
				return (magic * blend) + (main * (1 - blend)); // Add
			}

			ENDCG
		}
	}
}
