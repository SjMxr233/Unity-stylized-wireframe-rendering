// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/wireframe"
{
    Properties
    {
		[Toggle] _NoTriangle("NoTriangle",float)=0
		_wireThickness("wire thickness",Range(0,5))=0.05
		_wireColor("wire color",Color)=(1,1,1,1)
		_wireSmoothing("wire smoothing",Range(0,5))=1
		[Toggle] _DottedLine("DottedLine",float)=0
		_Repeats("Repeat",Range(1,10))=1
		_Length("length",Range(0,10))=1
		[Toggle]_Noise("Noise",float)=0
    }
    SubShader
    {
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "SimplexNoise4d.cginc"
		fixed4 _wireColor;
		half _wireThickness,_Length,_Repeats;
		half _wireSmoothing;
        struct v2g
        {
			float3 vpos:TEXCOORD0;
            float4 wpos : SV_POSITION;
        };

        struct g2f
        {
			float3 vpos:TEXCOORD1;
            float4 pos : SV_POSITION;
			float3 barycentric:TEXCOORD0;
        };
        v2g vert (appdata_base v)
        {
            v2g o;
			o.vpos=v.vertex.xyz;
            o.wpos = mul(unity_ObjectToWorld,v.vertex);
            return o;
        }
		[maxvertexcount(3)]
		void geom(triangle v2g p[3],inout TriangleStream<g2f> stream)
		{
			g2f o1,o2,o3;
			float3 param=float3(0,0,0);
			#if _NOTRIANGLE_ON
			float EdgeA = length(p[0].vpos - p[1].vpos);
            float EdgeB = length(p[1].vpos - p[2].vpos);
            float EdgeC = length(p[2].vpos - p[0].vpos);
			if(EdgeA > EdgeB && EdgeA > EdgeC)
                param.y = 1.;
            else if (EdgeB > EdgeC && EdgeB > EdgeA)
                param.x = 1.;
            else
                param.z = 1.;
			#endif
			o1.pos=mul(UNITY_MATRIX_VP,p[0].wpos);
			o2.pos=mul(UNITY_MATRIX_VP,p[1].wpos);
			o3.pos=mul(UNITY_MATRIX_VP,p[2].wpos);

			o1.barycentric=float3(1,0,0)+param;
			o2.barycentric=float3(0,0,1)+param;
			o3.barycentric=float3(0,1,0)+param;

			o1.vpos=p[0].vpos;
			o2.vpos=p[1].vpos;
			o3.vpos=p[2].vpos;

			stream.Append(o1);
			stream.Append(o2);
			stream.Append(o3);
			stream.RestartStrip();
		}
		inline float aa1 (float threshold, float dist) {
			float delta = fwidth(dist) * _wireSmoothing;
			threshold=threshold*delta;
			return smoothstep(threshold-delta, threshold+delta, dist);
		}
		inline float aa2(float threshold,float dist)
		{
			float delta=fwidth(dist)*0.5;
			return smoothstep(threshold-delta,threshold+delta,dist);
		}
		fixed4 fragfront (g2f i) : SV_Target
        {
			float3 barycentric=float3(i.barycentric.x,i.barycentric.y,i.barycentric.z);
			float thickness=_wireThickness;
			#if _DOTTEDLINE_ON
			float posAlong=max(barycentric.x,barycentric.y);

			float offset=1.0/_Repeats*_Length;
			offset+=_Time.y*0.5;
			float pattern=frac((posAlong+offset)*_Repeats);
			thickness=_wireThickness*(1.0-aa2(_Length,pattern));
			#endif
			float d=min(barycentric.x,min(barycentric.y,barycentric.z));
			#if _NOISE_ON
			float noiseoff=0.0;
			noiseoff += snoise(float4(i.vpos.xyz * 80.0, _Time.y)) * 0.12;
			d+=noiseoff;
			#endif
			float t=1-aa1(thickness,d);
			return fixed4(_wireColor.rgb,t);
        }
        fixed4 fragback (g2f i) : SV_Target
        {
			float3 barycentric=float3(i.barycentric.x,i.barycentric.y,i.barycentric.z);
			float thickness=_wireThickness;
			#if _DOTTEDLINE_ON
			float posAlong=max(barycentric.x,barycentric.y);

			float offset=1.0/_Repeats*_Length;
			offset+=_Time.y*0.5;
			float pattern=frac((posAlong+offset)*_Repeats);
			thickness=_wireThickness*(1.0-aa2(_Length,pattern));
			#endif
			float d=min(barycentric.x,min(barycentric.y,barycentric.z));
			#if _NOISE_ON
			float noiseoff=0.0;
			noiseoff += snoise(float4(i.vpos.xyz * 80.0, _Time.y)) * 0.12;
			d+=noiseoff;
			#endif
			float t=1-aa1(thickness,d);
			return fixed4(_wireColor.rgb,saturate(t-_wireColor.a));
        }
		ENDCG
        Pass
        {
			Cull front
			Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
			#pragma shader_feature _NOTRIANGLE_ON
			#pragma shader_feature _DOTTEDLINE_ON
			#pragma shader_feature _NOISE_ON
            #pragma vertex vert
            #pragma fragment fragback
			#pragma geometry geom
			#pragma target 4.0
           
            ENDCG
        }
		Pass
		{
           Cull back
		   Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
			#pragma shader_feature _NOTRIANGLE_ON
			#pragma shader_feature _DOTTEDLINE_ON
			#pragma shader_feature _NOISE_ON
            #pragma vertex vert
            #pragma fragment fragfront
			#pragma geometry geom
			#pragma target 4.0
            ENDCG
        }
    }
	FallBack "Diffuse"
}
