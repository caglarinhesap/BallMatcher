// Made with Amplify Shader Editor v1.9.8.1
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "S_UI_Particle"
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

        _Main_Tex("Main_Tex", 2D) = "white" {}
        _Flowmap("Flowmap", 2D) = "white" {}
        _NoiseSize("NoiseSize", Float) = 0.5
        _NoiseAmount("NoiseAmount", Float) = 0.14
        _NoiseSpeed("NoiseSpeed", Vector) = (0.1,0.1,0,0)
        _AlphaMask("AlphaMask", 2D) = "white" {}
        [Toggle(_USEMASK_ON)] _UseMask("UseMask?", Float) = 1
        _TexSpeed("TexSpeed", Vector) = (0,0,0,0)
        _MaskRotationSpeed("MaskRotationSpeed", Float) = 1
        _MaskStrength("MaskStrength", Float) = 1
        _ColorBoost("ColorBoost", Float) = 1
        _AlphaBoost("AlphaBoost", Float) = 1
        _BaseTexSize("BaseTexSize", Vector) = (1,1,0,0)
        [Toggle(_USERCHANNEL_ON)] _UseRChannel("UseRChannel?", Float) = 0
        [Toggle(_RANDOMUVOFFSET_ON)] _RandomUVOffset("RandomUVOffset?", Float) = 1

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
        Blend One OneMinusSrcAlpha, One OneMinusSrcAlpha
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
            #define ASE_NEEDS_VERT_COLOR
            #define ASE_NEEDS_FRAG_COLOR
            #pragma shader_feature_local _USERCHANNEL_ON
            #pragma shader_feature_local _RANDOMUVOFFSET_ON
            #pragma shader_feature_local _USEMASK_ON


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

            uniform sampler2D _Main_Tex;
            uniform float2 _BaseTexSize;
            uniform float2 _TexSpeed;
            uniform sampler2D _Flowmap;
            uniform float _NoiseSize;
            uniform float2 _NoiseSpeed;
            uniform float _NoiseAmount;
            uniform sampler2D _AlphaMask;
            uniform float _MaskRotationSpeed;
            uniform float _MaskStrength;
            uniform float _AlphaBoost;
            uniform float _ColorBoost;


            v2f vert(appdata_t v )
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                #ifdef _RANDOMUVOFFSET_ON
                float4 staticSwitch44 = v.color;
                #else
                float4 staticSwitch44 = float4( float2( 0,0 ), 0.0 , 0.0 );
                #endif
                float2 texCoord2 = v.texcoord.xy * float2( 1,1 ) + staticSwitch44.rg;
                float2 panner3 = ( 1.0 * _Time.y * _NoiseSpeed + texCoord2);
                float4 tex2DNode6 = tex2Dlod( _Flowmap, float4( ( _NoiseSize * panner3 ), 0, 0.0) );
                float2 temp_output_11_0 = ( ( tex2DNode6.r * _NoiseAmount ) + texCoord2 );
                float2 panner17 = ( 1.0 * _Time.y * _TexSpeed + temp_output_11_0);
                float4 tex2DNode23 = tex2Dlod( _Main_Tex, float4( ( _BaseTexSize * panner17 ), 0, 0.0) );
                float4 temp_cast_2 = (tex2DNode23.r).xxxx;
                #ifdef _USERCHANNEL_ON
                float4 staticSwitch25 = temp_cast_2;
                #else
                float4 staticSwitch25 = tex2DNode23;
                #endif
                float mulTime10 = _Time.y * _MaskRotationSpeed;
                float cos12 = cos( mulTime10 );
                float sin12 = sin( mulTime10 );
                float2 rotator12 = mul( temp_output_11_0 - float2( 0.5,0.5 ) , float2x2( cos12 , -sin12 , sin12 , cos12 )) + float2( 0.5,0.5 );
                #ifdef _USEMASK_ON
                float staticSwitch22 = ( tex2DNode6.r * ( tex2Dlod( _AlphaMask, float4( rotator12, 0, 0.0) ).r * _MaskStrength ) );
                #else
                float staticSwitch22 = 1.0;
                #endif
                float4 temp_output_36_0 = ( ( v.color.a * ( staticSwitch25 * saturate( staticSwitch22 ) ) ) * _AlphaBoost );
                

                v.vertex.xyz += temp_output_36_0.rgb;

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

                #ifdef _RANDOMUVOFFSET_ON
                float4 staticSwitch44 = IN.color;
                #else
                float4 staticSwitch44 = float4( float2( 0,0 ), 0.0 , 0.0 );
                #endif
                float2 texCoord2 = IN.texcoord.xy * float2( 1,1 ) + staticSwitch44.rg;
                float2 panner3 = ( 1.0 * _Time.y * _NoiseSpeed + texCoord2);
                float4 tex2DNode6 = tex2D( _Flowmap, ( _NoiseSize * panner3 ) );
                float2 temp_output_11_0 = ( ( tex2DNode6.r * _NoiseAmount ) + texCoord2 );
                float2 panner17 = ( 1.0 * _Time.y * _TexSpeed + temp_output_11_0);
                float4 tex2DNode23 = tex2D( _Main_Tex, ( _BaseTexSize * panner17 ) );
                float4 temp_cast_2 = (tex2DNode23.r).xxxx;
                #ifdef _USERCHANNEL_ON
                float4 staticSwitch25 = temp_cast_2;
                #else
                float4 staticSwitch25 = tex2DNode23;
                #endif
                float mulTime10 = _Time.y * _MaskRotationSpeed;
                float cos12 = cos( mulTime10 );
                float sin12 = sin( mulTime10 );
                float2 rotator12 = mul( temp_output_11_0 - float2( 0.5,0.5 ) , float2x2( cos12 , -sin12 , sin12 , cos12 )) + float2( 0.5,0.5 );
                #ifdef _USEMASK_ON
                float staticSwitch22 = ( tex2DNode6.r * ( tex2D( _AlphaMask, rotator12 ).r * _MaskStrength ) );
                #else
                float staticSwitch22 = 1.0;
                #endif
                float4 temp_output_36_0 = ( ( IN.color.a * ( staticSwitch25 * saturate( staticSwitch22 ) ) ) * _AlphaBoost );
                

                half4 color = ( ( _ColorBoost * ( staticSwitch25 * IN.color ) ) * temp_output_36_0 );

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
Node;AmplifyShaderEditor.Vector2Node;46;-4292.55,939.3126;Inherit;False;Constant;_Vector2;Vector 2;16;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.VertexColorNode;42;-4576,752;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;44;-4128,784;Inherit;False;Property;_RandomUVOffset;RandomUVOffset?;14;0;Create;True;0;0;0;False;0;False;0;1;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector2Node;1;-4032,96;Inherit;False;Property;_NoiseSpeed;NoiseSpeed;4;0;Create;True;0;0;0;False;0;False;0.1,0.1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-3968,352;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;3;-3712,112;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0.1,0.1;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;4;-3680,-16;Inherit;False;Property;_NoiseSize;NoiseSize;2;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;5;-3456,-32;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;6;-3264,96;Inherit;True;Property;_Flowmap;Flowmap;1;0;Create;True;0;0;0;False;0;False;-1;0e55a84d3700d4e468e0963c55db013d;0e55a84d3700d4e468e0963c55db013d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RangedFloatNode;7;-3008,320;Inherit;False;Property;_NoiseAmount;NoiseAmount;3;0;Create;True;0;0;0;False;0;False;0.14;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;-2784,112;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.06;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;9;-2720,560;Inherit;False;Property;_MaskRotationSpeed;MaskRotationSpeed;8;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;10;-2480,560;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;11;-2544,128;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;12;-2304,512;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-2176,768;Inherit;False;Property;_MaskStrength;MaskStrength;9;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;14;-2128,112;Inherit;False;Property;_TexSpeed;TexSpeed;7;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;15;-2080,496;Inherit;True;Property;_AlphaMask;AlphaMask;5;0;Create;True;0;0;0;False;0;False;-1;fc74f2230eb1a474ab9e5b47b939b9da;fc74f2230eb1a474ab9e5b47b939b9da;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;16;-1792,688;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;17;-1984,48;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;18;-2096,-288;Inherit;False;Property;_BaseTexSize;BaseTexSize;12;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;19;-1648,352;Inherit;False;Constant;_Float0;Float 0;7;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-1648,480;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;-1840,-128;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;22;-1456,432;Inherit;False;Property;_UseMask;UseMask?;6;0;Create;True;0;0;0;False;0;False;0;1;1;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;23;-1728,144;Inherit;True;Property;_Main_Tex;Main_Tex;0;0;Create;True;0;0;0;False;0;False;-1;1cc47995b72dcb241b87e056d97cd2d9;6679dd00d70eac945815e04ea3dcf4ac;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SaturateNode;24;-1216,496;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;25;-1264,128;Inherit;False;Property;_UseRChannel;UseRChannel?;13;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-1136,272;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;27;-1584,-112;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;28;-704,368;Inherit;False;Property;_AlphaBoost;AlphaBoost;11;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-752,96;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;-896,-160;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;35;-928,-320;Inherit;False;Property;_ColorBoost;ColorBoost;10;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-512,-208;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-528,272;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-432,-16;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;True;-1;3;AmplifyShaderEditor.MaterialInspector;0;3;S_UI_Particle;5056123faa0c79b47ab6ad7e8bf059a4;True;Default;0;0;Default;2;True;True;3;1;False;;10;False;;3;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;True;True;0;False;;False;True;True;True;True;True;0;True;_ColorMask;False;False;False;False;False;False;False;True;True;0;True;_Stencil;255;True;_StencilReadMask;255;True;_StencilWriteMask;0;True;_StencilComp;0;True;_StencilOp;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;0;True;unity_GUIZTestMode;False;True;5;Queue=Transparent=Queue=0;IgnoreProjector=True;RenderType=Transparent=RenderType;PreviewType=Plane;CanUseSpriteAtlas=True;False;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;False;0;;0;0;Standard;0;0;1;True;False;;False;0
WireConnection;44;1;46;0
WireConnection;44;0;42;0
WireConnection;2;1;44;0
WireConnection;3;0;2;0
WireConnection;3;2;1;0
WireConnection;5;0;4;0
WireConnection;5;1;3;0
WireConnection;6;1;5;0
WireConnection;8;0;6;1
WireConnection;8;1;7;0
WireConnection;10;0;9;0
WireConnection;11;0;8;0
WireConnection;11;1;2;0
WireConnection;12;0;11;0
WireConnection;12;2;10;0
WireConnection;15;1;12;0
WireConnection;16;0;15;1
WireConnection;16;1;13;0
WireConnection;17;0;11;0
WireConnection;17;2;14;0
WireConnection;20;0;6;1
WireConnection;20;1;16;0
WireConnection;21;0;18;0
WireConnection;21;1;17;0
WireConnection;22;1;19;0
WireConnection;22;0;20;0
WireConnection;23;1;21;0
WireConnection;24;0;22;0
WireConnection;25;1;23;0
WireConnection;25;0;23;1
WireConnection;26;0;25;0
WireConnection;26;1;24;0
WireConnection;29;0;27;4
WireConnection;29;1;26;0
WireConnection;33;0;25;0
WireConnection;33;1;27;0
WireConnection;34;0;35;0
WireConnection;34;1;33;0
WireConnection;36;0;29;0
WireConnection;36;1;28;0
WireConnection;37;0;34;0
WireConnection;37;1;36;0
WireConnection;0;0;37;0
WireConnection;0;1;36;0
ASEEND*/
//CHKSM=9537A3EE39A299A9AFE3080CFEAD6A8EF59F53D0