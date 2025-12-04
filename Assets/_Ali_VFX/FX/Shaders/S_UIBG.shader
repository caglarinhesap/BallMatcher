// Made with Amplify Shader Editor v1.9.8.1
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "S_UIBG"
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

        _netpng("net-png", 2D) = "white" {}
        _TextureSample1("Texture Sample 1", 2D) = "white" {}
        _RotateAngle("RotateAngle", Float) = 45
        _Size("Size", Float) = 1
        _Speed("Speed", Float) = 1
        _Cycle("Cycle", Float) = 3
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


        Cull Back
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend One One
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

            uniform sampler2D _TextureSample1;
            uniform float _Speed;
            uniform float _Cycle;
            uniform float _RotateAngle;
            uniform sampler2D _netpng;
            uniform float _Size;
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

                float mulTime78 = _Time.y * _Speed;
                float2 texCoord79 = IN.texcoord.xy * float2( 1,1 ) + float2( 0,-2 );
                float cos85 = cos( radians( _RotateAngle ) );
                float sin85 = sin( radians( _RotateAngle ) );
                float2 rotator85 = mul( texCoord79 - float2( 0,0 ) , float2x2( cos85 , -sin85 , sin85 , cos85 )) + float2( 0,0 );
                float2 panner89 = ( fmod( mulTime78 , _Cycle ) * float2( 1,0 ) + rotator85);
                float4 temp_cast_0 = (tex2D( _TextureSample1, saturate( panner89 ) ).r).xxxx;
                float2 texCoord65 = IN.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
                float2 temp_output_1_0_g1 = ( _Size * texCoord65 );
                float2 temp_output_11_0_g1 = ( temp_output_1_0_g1 - float2( 0,-0.28 ) );
                float2 break18_g1 = temp_output_11_0_g1;
                float2 appendResult19_g1 = (float2(break18_g1.y , -break18_g1.x));
                float dotResult12_g1 = dot( temp_output_11_0_g1 , temp_output_11_0_g1 );
                float2 panner71 = ( 1.0 * _Time.y * float2( -0.002,0.02 ) + ( temp_output_1_0_g1 + ( appendResult19_g1 * ( dotResult12_g1 * float2( 0.2,-0.38 ) ) ) + float2( 0,0 ) ));
                float4 blendOpSrc111 = temp_cast_0;
                float4 blendOpDest111 = ( ( tex2D( _netpng, panner71 ).a * 1.0 ) * IN.color );
                float4 lerpBlendMode111 = lerp(blendOpDest111,(( blendOpSrc111 > 0.5 ) ? max( blendOpDest111, 2.0 * ( blendOpSrc111 - 0.5 ) ) : min( blendOpDest111, 2.0 * blendOpSrc111 ) ),-10.0);
                

                half4 color = saturate( ( ( saturate( lerpBlendMode111 )) * _ColorBoost ) );

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
Node;AmplifyShaderEditor.TextureCoordinatesNode;65;-1264,0;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;66;-1136,-96;Inherit;False;Property;_Size;Size;3;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;68;-1184,288;Inherit;False;Constant;_Vector4;Vector 4;2;0;Create;True;0;0;0;False;0;False;0.2,-0.38;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;69;-1248,144;Inherit;False;Constant;_Vector3;Vector 3;2;0;Create;True;0;0;0;False;0;False;0,-0.28;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;-992,-64;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;76;-688,-496;Inherit;False;Property;_RotateAngle;RotateAngle;2;0;Create;True;0;0;0;False;0;False;45;150.06;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;77;-528,-368;Inherit;False;Property;_Speed;Speed;4;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;70;-864,16;Inherit;True;Radial Shear;-1;;1;c6dc9fc7fa9b08c4d95138f2ae88b526;0;4;1;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;84;-272,-272;Inherit;False;Property;_Cycle;Cycle;5;0;Create;True;0;0;0;False;0;False;3;5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;79;-592,-656;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,-2;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RadiansOpNode;80;-480,-496;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;78;-352,-368;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;85;-304,-608;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FmodOpNode;86;-80,-384;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;71;-496,-48;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.002,0.02;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;72;-240,-80;Inherit;True;Property;_netpng;net-png;0;0;Create;True;0;0;0;False;0;False;-1;41684b24a156a8e4199ac7a047c3ea3f;245607db541d9ad4d967625b59d1eca5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.PannerNode;89;48,-624;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VertexColorNode;22;208,224;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;73;176,-32;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;91;320,-672;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;544,192;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;98;528,-608;Inherit;True;Property;_TextureSample1;Texture Sample 1;1;0;Create;True;0;0;0;False;0;False;-1;9c3ab725d8e75044aac059a311348f68;2a10127afd6afea45bdb12669ff56559;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RangedFloatNode;107;-16,144;Inherit;False;Property;_ColorBoost;ColorBoost;6;0;Create;True;0;0;0;False;0;False;1;0.63;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;111;784,160;Inherit;True;PinLight;True;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;-10;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;112;1136,48;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;110;1392,-48;Inherit;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;1616,-80;Float;False;True;-1;3;AmplifyShaderEditor.MaterialInspector;0;3;S_UIBG;5056123faa0c79b47ab6ad7e8bf059a4;True;Default;0;0;Default;2;True;True;4;1;False;;1;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;True;True;0;False;;True;True;True;True;True;True;0;True;_ColorMask;False;False;False;False;False;False;False;True;True;0;True;_Stencil;255;True;_StencilReadMask;255;True;_StencilWriteMask;0;True;_StencilComp;0;True;_StencilOp;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;0;True;unity_GUIZTestMode;False;True;5;Queue=Transparent=Queue=0;IgnoreProjector=True;RenderType=Transparent=RenderType;PreviewType=Plane;CanUseSpriteAtlas=True;False;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;False;0;;0;0;Standard;0;0;1;True;False;;False;0
WireConnection;67;0;66;0
WireConnection;67;1;65;0
WireConnection;70;1;67;0
WireConnection;70;2;69;0
WireConnection;70;3;68;0
WireConnection;80;0;76;0
WireConnection;78;0;77;0
WireConnection;85;0;79;0
WireConnection;85;2;80;0
WireConnection;86;0;78;0
WireConnection;86;1;84;0
WireConnection;71;0;70;0
WireConnection;72;1;71;0
WireConnection;89;0;85;0
WireConnection;89;1;86;0
WireConnection;73;0;72;4
WireConnection;91;0;89;0
WireConnection;74;0;73;0
WireConnection;74;1;22;0
WireConnection;98;1;91;0
WireConnection;111;0;98;1
WireConnection;111;1;74;0
WireConnection;112;0;111;0
WireConnection;112;1;107;0
WireConnection;110;0;112;0
WireConnection;0;0;110;0
ASEEND*/
//CHKSM=54C3C487558B7EE4CC55F21C79192A15402FDFE3