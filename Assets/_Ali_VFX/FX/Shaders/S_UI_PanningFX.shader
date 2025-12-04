// Made with Amplify Shader Editor v1.9.8.1
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "S_UI_PanningFX"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0

        _BaseTex("BaseTex", 2D) = "white" {}
        _FlowmapTex("FlowmapTex", 2D) = "white" {}
        _MainTexAngle("MainTexAngle", Float) = 0
        _TexSpeed("TexSpeed", Vector) = (1,0,0,0)
        _FlowmapSpeed("FlowmapSpeed", Vector) = (2,0,0,0)
        [Toggle(_USETEXFORMASK_ON)] _UseTexForMask("UseTexForMask?", Float) = 0
        _MaskThreshold("MaskThreshold", Float) = 0.23
        [Toggle(_USEY_ON)] _UseY("UseY?", Float) = 0
        _FlowmapAmount("FlowmapAmount", Float) = 0.1
        _TexSize("TexSize", Float) = 1
        _FlowmapSize("FlowmapSize", Float) = 1
        _Mask("Mask", 2D) = "white" {}
        _EdgeMaskX("EdgeMaskX", Float) = 0.01
        _EdgeMaskY("EdgeMaskY", Float) = 0.01
        _ColorBoost("ColorBoost", Float) = 1

    }

    SubShader
    {
		LOD 0

        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }

        Stencil
        {
        	Ref [_Stencil]
        	ReadMask [_StencilReadMask]
        	WriteMask [_StencilWriteMask]
        	Comp [_StencilComp]
        	Pass [_StencilOp]
        }


        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend One OneMinusSrcAlpha
        ColorMask [_ColorMask]

        
        Pass
        {
            Name "Default"
        CGPROGRAM
            #define ASE_VERSION 19801

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            #include "UnityShaderVariables.cginc"
            #define ASE_NEEDS_FRAG_COLOR
            #pragma shader_feature_local _USETEXFORMASK_ON
            #pragma shader_feature_local _USEY_ON


            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                float4  mask : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
                
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            float _UIMaskSoftnessX;
            float _UIMaskSoftnessY;

            uniform sampler2D _BaseTex;
            uniform sampler2D _FlowmapTex;
            uniform float2 _FlowmapSpeed;
            uniform float _FlowmapSize;
            uniform float _FlowmapAmount;
            uniform float2 _TexSpeed;
            uniform float _MainTexAngle;
            uniform float _TexSize;
            uniform sampler2D _Mask;
            uniform float _MaskThreshold;
            uniform float _EdgeMaskX;
            uniform float _EdgeMaskY;
            uniform float _ColorBoost;


            v2f vert(appdata_t v )
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                

                v.vertex.xyz +=  float3( 0, 0, 0 ) ;

                float4 vPosition = UnityObjectToClipPos(v.vertex);
                OUT.worldPosition = v.vertex;
                OUT.vertex = vPosition;

                float2 pixelSize = vPosition.w;
                pixelSize /= float2(1, 1) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));

                float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
                OUT.texcoord = v.texcoord;
                OUT.mask = float4(v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy)));

                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN ) : SV_Target
            {
                //Round up the alpha color coming from the interpolator (to 1.0/256.0 steps)
                //The incoming alpha could have numerical instability, which makes it very sensible to
                //HDR color transparency blend, when it blends with the world's texture.
                const half alphaPrecision = half(0xff);
                const half invAlphaPrecision = half(1.0/alphaPrecision);
                IN.color.a = round(IN.color.a * alphaPrecision)*invAlphaPrecision;

                float2 texCoord31 = IN.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
                float2 panner30 = ( 1.0 * _Time.y * _FlowmapSpeed + texCoord31);
                float2 texCoord5 = IN.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
                float cos3 = cos( radians( _MainTexAngle ) );
                float sin3 = sin( radians( _MainTexAngle ) );
                float2 rotator3 = mul( texCoord5 - float2( 0,0 ) , float2x2( cos3 , -sin3 , sin3 , cos3 )) + float2( 0,0 );
                float2 panner7 = ( 1.0 * _Time.y * _TexSpeed + rotator3);
                float2 temp_output_26_0 = ( ( tex2D( _FlowmapTex, ( panner30 * _FlowmapSize ) ).r * _FlowmapAmount ) + ( panner7 * _TexSize ) );
                float2 texCoord10 = IN.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
                #ifdef _USEY_ON
                float staticSwitch21 = ( 1.0 - texCoord10.y );
                #else
                float staticSwitch21 = ( 1.0 - texCoord10.x );
                #endif
                #ifdef _USETEXFORMASK_ON
                float staticSwitch19 = saturate( ( ( staticSwitch21 * tex2D( _Mask, temp_output_26_0 ).r ) * 5.0 ) );
                #else
                float staticSwitch19 = staticSwitch21;
                #endif
                float HalfUMask51 = saturate( ( texCoord10.x - _EdgeMaskX ) );
                float WholeVMask59 = saturate( ( ( ( texCoord10.y * ( 1.0 - texCoord10.y ) ) - _EdgeMaskY ) * 4.33 ) );
                

                half4 color = ( IN.color * ( ( saturate( ( tex2D( _BaseTex, temp_output_26_0 ).r - ( staticSwitch19 - _MaskThreshold ) ) ) * HalfUMask51 * WholeVMask59 ) * _ColorBoost ) );

                #ifdef UNITY_UI_CLIP_RECT
                half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw);
                color.a *= m.x * m.y;
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                color.rgb *= color.a;

                return color;
            }
        ENDCG
        }
    }
    CustomEditor "AmplifyShaderEditor.MaterialInspector"
	
	Fallback Off
}
/*ASEBEGIN
Version=19801
Node;AmplifyShaderEditor.RangedFloatNode;6;-1760,16;Inherit;False;Property;_MainTexAngle;MainTexAngle;2;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;31;-1824,-480;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;32;-1744,-352;Inherit;False;Property;_FlowmapSpeed;FlowmapSpeed;4;0;Create;True;0;0;0;False;0;False;2,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RadiansOpNode;2;-1568,16;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;5;-1632,-128;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;30;-1568,-464;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;35;-1552,-336;Inherit;False;Property;_FlowmapSize;FlowmapSize;10;0;Create;True;0;0;0;False;0;False;1;1.76;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;3;-1376,-112;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;8;-1296,32;Inherit;False;Property;_TexSpeed;TexSpeed;3;0;Create;True;0;0;0;False;0;False;1,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-1344,-368;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;28;-1120,-176;Inherit;False;Property;_FlowmapAmount;FlowmapAmount;8;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;7;-1104,-96;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;34;-1072,112;Inherit;False;Property;_TexSize;TexSize;9;0;Create;True;0;0;0;False;0;False;1;1.76;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;29;-1168,-400;Inherit;True;Property;_FlowmapTex;FlowmapTex;1;0;Create;True;0;0;0;False;0;False;-1;27dea7535006c274eb124b806535abc3;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;-920.823,56.573;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;-864,-192;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;10;-1808,272;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;22;-901.0908,448.9813;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;11;-896,256;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;26;-768,-16;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;21;-576,272;Inherit;True;Property;_UseY;UseY?;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;37;-544,608;Inherit;True;Property;_Mask;Mask;11;0;Create;True;0;0;0;False;0;False;-1;3e788240fc1a09e4894a2a7c99e70249;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;-256,544;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;55;-2208,688;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;0,672;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-2048,656;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;64;-2032,880;Inherit;False;Property;_EdgeMaskY;EdgeMaskY;13;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;57;-1792,656;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;48;176,576;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;63;-1628.559,533.0339;Inherit;False;Property;_EdgeMaskX;EdgeMaskX;12;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;19;-96,224;Inherit;False;Property;_UseTexForMask;UseTexForMask?;5;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;56;-1600,656;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;4.33;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;13;48,336;Inherit;False;Property;_MaskThreshold;MaskThreshold;6;0;Create;True;0;0;0;False;0;False;0.23;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;53;-1424,448;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-528,-32;Inherit;True;Property;_BaseTex;BaseTex;0;0;Create;True;0;0;0;False;0;False;-1;60e64a9271ad91943ba6c4dd53f4f01d;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleSubtractOpNode;18;240,240;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;58;-1408,656;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;61;-1200,480;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;17;544,16;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;59;-1264,656;Inherit;False;WholeVMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;51;-1024,528;Inherit;True;HalfUMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;39;752,16;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;52;592,320;Inherit;False;51;HalfUMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;62;592,416;Inherit;False;59;WholeVMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;896,288;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;1023.023,562.9389;Inherit;False;Property;_ColorBoost;ColorBoost;14;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;65;1152,336;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;41;1120,-16;Inherit;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;1472,80;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;1728,80;Float;False;True;-1;3;AmplifyShaderEditor.MaterialInspector;0;3;S_UI_PanningFX;5056123faa0c79b47ab6ad7e8bf059a4;True;Default;0;0;Default;2;True;True;3;1;False;;10;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;True;True;True;True;True;0;True;_ColorMask;False;False;False;False;False;False;False;True;True;0;True;_Stencil;255;True;_StencilReadMask;255;True;_StencilWriteMask;0;True;_StencilComp;0;True;_StencilOp;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;0;True;unity_GUIZTestMode;False;True;5;Queue=Transparent=Queue=0;IgnoreProjector=True;RenderType=Transparent=RenderType;PreviewType=Plane;CanUseSpriteAtlas=True;False;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;False;0;;0;0;Standard;0;0;1;True;False;;False;0
WireConnection;2;0;6;0
WireConnection;30;0;31;0
WireConnection;30;2;32;0
WireConnection;3;0;5;0
WireConnection;3;2;2;0
WireConnection;36;0;30;0
WireConnection;36;1;35;0
WireConnection;7;0;3;0
WireConnection;7;2;8;0
WireConnection;29;1;36;0
WireConnection;33;0;7;0
WireConnection;33;1;34;0
WireConnection;27;0;29;1
WireConnection;27;1;28;0
WireConnection;22;0;10;2
WireConnection;11;0;10;1
WireConnection;26;0;27;0
WireConnection;26;1;33;0
WireConnection;21;1;11;0
WireConnection;21;0;22;0
WireConnection;37;1;26;0
WireConnection;38;0;21;0
WireConnection;38;1;37;1
WireConnection;55;0;10;2
WireConnection;47;0;38;0
WireConnection;54;0;10;2
WireConnection;54;1;55;0
WireConnection;57;0;54;0
WireConnection;57;1;64;0
WireConnection;48;0;47;0
WireConnection;19;1;21;0
WireConnection;19;0;48;0
WireConnection;56;0;57;0
WireConnection;53;0;10;1
WireConnection;53;1;63;0
WireConnection;1;1;26;0
WireConnection;18;0;19;0
WireConnection;18;1;13;0
WireConnection;58;0;56;0
WireConnection;61;0;53;0
WireConnection;17;0;1;1
WireConnection;17;1;18;0
WireConnection;59;0;58;0
WireConnection;51;0;61;0
WireConnection;39;0;17;0
WireConnection;49;0;39;0
WireConnection;49;1;52;0
WireConnection;49;2;62;0
WireConnection;65;0;49;0
WireConnection;65;1;66;0
WireConnection;40;0;41;0
WireConnection;40;1;65;0
WireConnection;0;0;40;0
ASEEND*/
//CHKSM=62AB20DB8F82CA27B61F20D6CF00759750E16BF8