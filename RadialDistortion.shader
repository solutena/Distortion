Shader "Solutena/Screen/RadialDistortion"
{
	Properties
	{
		_DistTex("Distortion Texture", 2D) = "white" {}
		_MaskTex("MaskTex",2D) = "white" {}

		_Offset("Offset",Vector) = (0,0,0.5,0.5)
		_Intensity("Intensity",Float) = 0
	}
	SubShader
	{
		Tags {"Queue" = "Transparent" "RenderType" = "Transparent" }

		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		ZWrite Off

		GrabPass{}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex		: POSITION;
				float2 distUV		: TEXCOORD0;
				float2 maskUV	: TEXCOORD1;
			};

			struct v2f
			{
				float4 vertex		: SV_POSITION;
				float2 screenUV	: TEXCOORD0;
				float2 distUV		: TEXCOORD1;
				float2 maskUV	: TEXCOORD2;
			};

			sampler2D _GrabTexture;
			sampler2D _DistTex;
			sampler2D _MaskTex;
			float4 _GrabTexture_ST;
			float4 _DistTex_ST;
			float4 _MaskTex_ST;
			float4 _Offset;
			float _Intensity;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenUV = ComputeGrabScreenPos(o.vertex);
				o.distUV = TRANSFORM_TEX(v.distUV, _DistTex);
				o.maskUV = TRANSFORM_TEX(v.maskUV, _MaskTex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float2 ratio = float2(1,_ScreenParams.y / _ScreenParams.x);
				float2 center = _Offset.zw*ratio;
				float2 distUV = i.distUV*ratio;
				float2 maskUV = i.maskUV*ratio;
				float2 Angle = distUV - center;

				float2 radialMainUV = _Offset.xy;
				radialMainUV.x += ((1 - (length(distUV - center) * 2)));
				radialMainUV.y += ((atan2(Angle.y, Angle.x) + 3.14159265359f) / 6.28318530718f);
				
				float2 radialMaskUV = 0;
				radialMaskUV.x += ((1 - (length(maskUV - center) * 2)));
				radialMaskUV.y += ((atan2(Angle.y, Angle.x) + 3.14159265359f) / 6.28318530718f);

				float2 radialOffset = tex2D(_DistTex, radialMainUV).rg * (i.distUV-0.5);
				float2 mainUV = i.screenUV + (radialOffset * _Intensity);
				float4 main = tex2D(_GrabTexture, mainUV);
				float4 mask = tex2D(_MaskTex, radialMaskUV);

				main.a *= mask.g;
				clip(main.a - 0.001);

				return main;
			}
			ENDCG
		}
	}
}
