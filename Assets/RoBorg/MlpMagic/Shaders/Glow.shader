// Make the magic objects (_MainTex) glow
Shader "Hidden/MlpMagic/Glow"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_MagicGradientTex("Gradient", 2D) = "white" {}
		_MaskDepthBuffer("MaskDepthBuffer", 2D) = "white" {}
		_SceneDepthBuffer("SceneDepthBuffer", 2D) = "white" {}
		_UseInnerGradient("User Inner Gradient", Float) = 0
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
				//float depth;
			};

			struct closestPixel
			{
				float distance;
				float sqrDistance;
				float depth;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				//o.depth = -UnityObjectToViewPos(v.vertex) * _ProjectionParams.w;

				return o;
			}

			SamplerState sampler_MainTex
			{
				Filter = MIN_MAG_MIP_POINT;
				AddressU = Clamp;
				AddressV = Clamp;
			};

			Texture2D _MainTex;
			sampler2D _MagicGradientTex;
			sampler2D _MaskDepthBuffer;
			sampler2D _SceneDepthBuffer;
			float _Intensity;
			float _UseInnerGradient;

			/// <summary>
			/// Get information about the closest magic-item-pixel to the pixel we're looking at
			/// </summary>
			/// <param name="uv">The UV to look at</param>
			/// <param name="width">The width of the glow</param>
			/// <param name="r">The red value of the pixel we're rendering (0 or 1)</param>
			/// <param name="steps">The number of steps to look at</param>
			/// <param name="mip">The mip-map level to look at</param>
			closestPixel getSquareDistanceMip(float2 uv, float width, float r, float steps, uint mip)
			{
				float widthPerStep = width / steps;
				closestPixel px;

				px.distance = 2;
				px.sqrDistance = (width * width) + 1;
				px.depth = 2;

				[loop] for (float y = -steps; y <= steps; y += 1)
				{
					float dv = widthPerStep * y;

					[loop] for (float x = -steps; x <= steps; x += 1)
					{
						float du = widthPerStep * x;
						float2 sampleUv = float2(uv.x + du, uv.y + dv);

						fixed4 col = _MainTex.SampleLevel(sampler_MainTex, sampleUv, mip);
						
						// Ignore antialiased part as the depth buffer isn't antialiased
						if (mip > 0 || ((col.r == 1) && (col.g == 1) && (col.b == 1)) || ((col.r == 0) && (col.g == 0) && (col.b == 0)))
						{
							float currentDistance = (du * du) + (dv * dv) + ((col.r == r) * 99);

							if (currentDistance < px.sqrDistance)
							{
								px.sqrDistance = currentDistance;
								px.depth = Linear01Depth(tex2D(_MaskDepthBuffer, sampleUv));
							}
						}
					}
				}

				return px;
			}

			/// <summary>
			/// Get information about the closest magic-item-pixel to the pixel we're looking at.
			/// For speed, go over the image several times at increasing resolution.
			/// If the low-resolution scan doesn't find a pixel then we can early-exit.
			/// </summary>
			/// <param name="uv">The UV to look at</param>
			/// <param name="width">The width of the glow</param>
			/// <param name="r">The red value of the pixel we're rendering (0 or 1)</param>
			closestPixel getDistance(float2 uv, float width, float r)
			{
				closestPixel px;

				px.distance = 2;

				if (getSquareDistanceMip(uv, width, r, 0.5, 5).sqrDistance > 1)
				{
					return px;
				}

				if (getSquareDistanceMip(uv, width, r, 1, 4).sqrDistance > 1)
				{
					return px;
				}

				if (getSquareDistanceMip(uv, width, r, 2, 3).sqrDistance > 1)
				{
					return px;
				}

				if (getSquareDistanceMip(uv, width, r, 4, 2).sqrDistance > 1)
				{
					return px;
				}

				// FPS actually drops if we use this mip level
				// if (getSquareDistanceMip(uv, width, r, 8, 1).sqrDistance > 1)
				// {
				// 	return px;
				// }
				
				px = getSquareDistanceMip(uv, width, r, 16, 0);

				// Return distance as a fraction of the glow width
				// Can still be >1, but this would be outside the glow so should be discarded later
				px.distance = sqrt(px.sqrDistance) / width;

				return px;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed gradientU;
				fixed4 col = _MainTex.SampleLevel(sampler_MainTex, i.uv, 0);

				// The width of the glow in UVs
				float glowWidth = 0.02; // TODO: * (1 - depth);

				if (_UseInnerGradient)
				{
					// Sneaky - means black will use the left half of the texture, white the right
					gradientU = (round(col.r) + 0.5) * .5;
				}
				else
				{
					if (col.r > 0)
					{
						return fixed4(0, 0, 0, 0);
					}

					gradientU = 0.25;
				}

				closestPixel px = getDistance(i.uv, glowWidth, col.r);

				// Pixel is too far from gradient source
				if (px.distance > 1)
				{
					return fixed4(0, 0, 0, 0);
				}

				// Pixel is behind another object
				if (px.depth > Linear01Depth(tex2D(_SceneDepthBuffer, i.uv)))
				{
					return fixed4(0, 0, 0, 0);
				}

				// Sample the gradient using the distance as the v value
				return tex2D(_MagicGradientTex, fixed2(gradientU, px.distance));
			}

			ENDCG
		}
	}
}
