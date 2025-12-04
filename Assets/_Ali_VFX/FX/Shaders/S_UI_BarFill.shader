// Made with Amplify Shader Editor v1.9.8.1
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "S_UI_BarFill"
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

        _LerpAlpha("LerpAlpha", Float) = 0.5
        _Detail1("Detail1", 2D) = "white" {}
        _LeftColor("LeftColor", Color) = (1,0,0,0)
        _RightColor("RightColor", Color) = (0,0.2601228,1,0)
        _FlowmapTex("FlowmapTex", 2D) = "white" {}
        _FlowmapStrength("FlowmapStrength", Float) = 0.1
        _FlowmapInfluence("FlowmapInfluence", Float) = 0.09
        _DetailTexSpeed("DetailTexSpeed", Vector) = (0.3,0,0,0)
        [Toggle(_USEDETAIL_ON)] _UseDetail("UseDetail?", Float) = 1
        _FlowmapSpeed("FlowmapSpeed", Vector) = (1,0,0,0)
        _DetailSize("DetailSize", Vector) = (0.2,1,0,0)
        _DetailEdgeSize("DetailEdgeSize", Range( 0 , 0.6)) = 0
        _DetailStrength("DetailStrength", Range( 0 , 5)) = 1
        _TexBorder("TexBorder", 2D) = "white" {}
        _BorderColor("BorderColor", Color) = (1,0.9729279,0,0)
        [Toggle(_USEBORDER_ON)] _UseBorder("UseBorder?", Float) = 0
        _FlowmapSize("FlowmapSize", Vector) = (0.5,0.5,0,0)
        [HDR]_RightDetailColor("RightDetailColor", Color) = (1,1,1)
        [HDR]_LeftDetailColor("LeftDetailColor", Color) = (1,1,1)
        [HideInInspector] _texcoord( "", 2D ) = "white" {}

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
        ZTest [_ColorMask]
        Blend SrcAlpha OneMinusSrcAlpha
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
            #pragma shader_feature_local _USEBORDER_ON
            #pragma shader_feature_local _USEDETAIL_ON


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

            uniform float _DetailStrength;
            uniform float _DetailEdgeSize;
            uniform sampler2D _Detail1;
            uniform float _LerpAlpha;
            uniform float _FlowmapStrength;
            uniform sampler2D _FlowmapTex;
            uniform float2 _FlowmapSpeed;
            uniform float2 _FlowmapSize;
            uniform float _FlowmapInfluence;
            uniform float2 _DetailTexSpeed;
            uniform float2 _DetailSize;
            uniform float3 _RightDetailColor;
            uniform float4 _RightColor;
            uniform float4 _LeftColor;
            uniform float3 _LeftDetailColor;
            uniform sampler2D _TexBorder;
            uniform float4 _TexBorder_ST;
            uniform float4 _BorderColor;


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

                float3 temp_cast_0 = (0.0).xxx;
                float2 texCoord80 = IN.texcoord.xy * float2( -1,1 ) + float2( 0,0 );
                float2 texCoord1 = IN.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
                float FlowmapStrength_Ref244 = _FlowmapStrength;
                float2 FlowmapSpeed_Ref272 = _FlowmapSpeed;
                float2 FlowmapSize_Ref260 = _FlowmapSize;
                float2 texCoord280 = IN.texcoord.xy * ( FlowmapSize_Ref260 * float2( 2,2 ) ) + float2( 0,0 );
                float2 panner283 = ( 1.0 * _Time.y * ( FlowmapSpeed_Ref272 * float2( 2,2 ) ) + texCoord280);
                float FlowmapInfluence_Ref259 = _FlowmapInfluence;
                float2 DetailTexSpeed_Ref257 = _DetailTexSpeed;
                float2 DetailSize_Ref258 = _DetailSize;
                float2 texCoord293 = IN.texcoord.xy * ( ( DetailSize_Ref258 * float2( 5,1 ) ) * float2( 1,1 ) ) + float2( 0,0 );
                float2 panner296 = ( 1.0 * _Time.y * ( DetailTexSpeed_Ref257 * float2( 7,0 ) ) + texCoord293);
                float2 texCoord16 = IN.texcoord.xy * _FlowmapSize + float2( 0,0 );
                float2 panner17 = ( 1.0 * _Time.y * _FlowmapSpeed + texCoord16);
                float2 texCoord12 = IN.texcoord.xy * _DetailSize + float2( 0,0 );
                float2 panner11 = ( 1.0 * _Time.y * _DetailTexSpeed + texCoord12);
                float smoothstepResult86 = smoothstep( _DetailEdgeSize , 1.0 , ( ( tex2D( _Detail1, texCoord80 ).a * ( texCoord1.x - _LerpAlpha ) ) * ( tex2D( _Detail1, ( ( ( FlowmapStrength_Ref244 + 0.1 ) * saturate( ( tex2D( _FlowmapTex, panner283 ).r - ( texCoord280.x - ( FlowmapInfluence_Ref259 + 0.35 ) ) ) ) ) + panner296 ) ).b + tex2D( _Detail1, ( ( _FlowmapStrength * saturate( ( tex2D( _FlowmapTex, panner17 ).r - ( texCoord16.x - _FlowmapInfluence ) ) ) ) + panner11 ) ).r ) ));
                #ifdef _USEDETAIL_ON
                float3 staticSwitch29 = ( ( _DetailStrength * smoothstepResult86 ) * _RightDetailColor );
                #else
                float3 staticSwitch29 = temp_cast_0;
                #endif
                float3 temp_cast_2 = (0.0).xxx;
                float DetailStrength_Ref304 = _DetailStrength;
                float DetailEdgeSize_Ref263 = _DetailEdgeSize;
                float2 texCoord237 = IN.texcoord.xy * float2( 1,1 ) + float2( 0,0 );
                float2 texCoord167 = IN.texcoord.xy * ( FlowmapSize_Ref260 * float2( 2,2 ) ) + float2( 0,0 );
                float2 panner172 = ( 1.0 * _Time.y * ( float2( -1,1 ) * ( FlowmapSpeed_Ref272 * float2( 2,2 ) ) ) + texCoord167);
                float2 texCoord189 = IN.texcoord.xy * ( ( DetailSize_Ref258 * float2( 5,1 ) ) * float2( 1,1 ) ) + float2( 0,0 );
                float2 panner194 = ( 1.0 * _Time.y * ( ( DetailTexSpeed_Ref257 * float2( -1,1 ) ) * float2( 7,0 ) ) + texCoord189);
                float2 texCoord165 = IN.texcoord.xy * FlowmapSize_Ref260 + float2( 0,0 );
                float2 panner170 = ( 1.0 * _Time.y * ( float2( -1,1 ) * FlowmapSpeed_Ref272 ) + texCoord165);
                float2 texCoord187 = IN.texcoord.xy * DetailSize_Ref258 + float2( 0,0 );
                float2 panner192 = ( 1.0 * _Time.y * ( DetailTexSpeed_Ref257 * float2( -1,1 ) ) + texCoord187);
                float smoothstepResult228 = smoothstep( DetailEdgeSize_Ref263 , 1.0 , ( ( ( ( 1.0 - texCoord1.x ) - ( 1.0 - _LerpAlpha ) ) * tex2D( _Detail1, texCoord237 ).a ) * ( tex2D( _Detail1, ( ( ( FlowmapStrength_Ref244 + 0.1 ) * saturate( -( tex2D( _FlowmapTex, panner172 ).r - ( texCoord167.x - ( FlowmapInfluence_Ref259 + 0.35 ) ) ) ) ) + panner194 ) ).b + tex2D( _Detail1, ( ( FlowmapStrength_Ref244 * saturate( -( tex2D( _FlowmapTex, panner170 ).r - ( texCoord165.x - FlowmapInfluence_Ref259 ) ) ) ) + panner192 ) ).r ) ));
                #ifdef _USEDETAIL_ON
                float3 staticSwitch234 = ( ( DetailStrength_Ref304 * smoothstepResult228 ) * _LeftDetailColor );
                #else
                float3 staticSwitch234 = temp_cast_2;
                #endif
                float4 lerpResult4 = lerp( ( float4( staticSwitch29 , 0.0 ) + ( IN.color * _RightColor ) ) , ( ( IN.color * _LeftColor ) + float4( staticSwitch234 , 0.0 ) ) , saturate( step( texCoord1.x , _LerpAlpha ) ));
                float2 uv_TexBorder = IN.texcoord.xy * _TexBorder_ST.xy + _TexBorder_ST.zw;
                float4 tex2DNode250 = tex2D( _TexBorder, uv_TexBorder );
                float4 blendOpSrc255 = ( tex2DNode250.r * ( IN.color * _BorderColor ) );
                float4 blendOpDest255 = lerpResult4;
                float4 lerpBlendMode255 = lerp(blendOpDest255,(( blendOpSrc255 > 0.5 ) ? max( blendOpDest255, 2.0 * ( blendOpSrc255 - 0.5 ) ) : min( blendOpDest255, 2.0 * blendOpSrc255 ) ),tex2DNode250.r);
                #ifdef _USEBORDER_ON
                float4 staticSwitch256 = ( saturate( lerpBlendMode255 ));
                #else
                float4 staticSwitch256 = lerpResult4;
                #endif
                

                half4 color = staticSwitch256;

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
Node;AmplifyShaderEditor.Vector2Node;45;-3728,-880;Inherit;False;Property;_FlowmapSize;FlowmapSize;16;0;Create;True;0;0;0;False;0;False;0.5,0.5;0.5,0.5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;46;-3504,-1040;Inherit;False;Property;_FlowmapSpeed;FlowmapSpeed;9;0;Create;True;0;0;0;False;0;False;1,0;1,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;260;-3504,-688;Inherit;False;FlowmapSize_Ref;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;272;-3280,-1120;Inherit;False;FlowmapSpeed_Ref;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;24;-3248,-720;Inherit;False;Property;_FlowmapInfluence;FlowmapInfluence;6;0;Create;True;0;0;0;False;0;False;0.09;0.09;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;314;-3408,352;Inherit;False;272;FlowmapSpeed_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;315;-3600,544;Inherit;False;260;FlowmapSize_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;207;-3280,1456;Inherit;False;Constant;_Vector2;Vector 0;37;0;Create;True;0;0;0;False;0;False;-1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;164;-3328,688;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;2,2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;168;-3136,496;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;2,2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;203;-3216,208;Inherit;False;Constant;_Vector0;Vector 0;37;0;Create;True;0;0;0;False;0;False;-1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;310;-3392,-1824;Inherit;False;260;FlowmapSize_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;259;-3024,-624;Inherit;True;FlowmapInfluence_Ref;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;320;-3168,1872;Inherit;False;260;FlowmapSize_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;321;-3424,1728;Inherit;False;272;FlowmapSpeed_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;206;-3104,1504;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;51;-3200,-512;Inherit;False;Property;_DetailSize;DetailSize;10;0;Create;True;0;0;0;False;0;False;0.2,1;0.2,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;165;-2976,1648;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.5,0.5;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;167;-3120,656;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.5,0.5;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;201;-2976,416;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;277;-3184,-1824;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;2,2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;311;-3264,-2032;Inherit;False;272;FlowmapSpeed_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;316;-2992,784;Inherit;False;259;FlowmapInfluence_Ref;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;170;-2752,1504;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;16;-3296,-896;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.5,0.5;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;258;-2976,-336;Inherit;False;DetailSize_Ref;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;271;-2811.546,1926.054;Inherit;False;259;FlowmapInfluence_Ref;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;172;-2832,512;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;173;-2688,752;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.35;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;278;-2992,-2016;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;2,2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;280;-2976,-1856;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.5,0.5;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;309;-3022.17,-1671.143;Inherit;False;259;FlowmapInfluence_Ref;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;27;-2688,-480;Inherit;False;Property;_DetailTexSpeed;DetailTexSpeed;7;0;Create;True;0;0;0;False;0;False;0.3,0;0.3,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleSubtractOpNode;174;-2496,1680;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0.06;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;175;-2576,1472;Inherit;True;Property;_FlowmapTex2;FlowmapTex;4;0;Create;True;0;0;0;False;0;False;18;ddcaa6cb05170b64c86ef89fca4559c7;ddcaa6cb05170b64c86ef89fca4559c7;True;0;False;white;Auto;False;Instance;18;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.PannerNode;17;-3056,-1040;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-2464,-992;Inherit;False;Property;_FlowmapStrength;FlowmapStrength;5;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;176;-2576,688;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0.06;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;177;-2656,480;Inherit;True;Property;_FlowmapTex3;FlowmapTex;4;0;Create;True;0;0;0;False;0;False;18;ddcaa6cb05170b64c86ef89fca4559c7;ddcaa6cb05170b64c86ef89fca4559c7;True;0;False;white;Auto;False;Instance;18;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleAddOpNode;284;-2544,-1760;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.35;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;257;-2448,-400;Inherit;False;DetailTexSpeed_Ref;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;306;-3008,-1584;Inherit;False;258;DetailSize_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;312;-3328,928;Inherit;False;258;DetailSize_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;283;-2704,-2000;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;179;-2288,1648;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;22;-2800,-864;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0.06;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;244;-2224,-1024;Inherit;False;FlowmapStrength_Ref;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;180;-2368,656;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;204;-2736,1216;Inherit;False;Constant;_Vector1;Vector 0;37;0;Create;True;0;0;0;False;0;False;-1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleSubtractOpNode;285;-2432,-1824;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0.06;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;307;-2784,-1584;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;5,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;313;-3104,928;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;5,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;317;-2832,1120;Inherit;False;257;DetailTexSpeed_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;286;-2512,-2032;Inherit;True;Property;_FlowmapTex4;FlowmapTex;4;0;Create;True;0;0;0;False;0;False;18;ddcaa6cb05170b64c86ef89fca4559c7;ddcaa6cb05170b64c86ef89fca4559c7;True;0;False;white;Auto;False;Instance;18;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SamplerNode;18;-2880,-1072;Inherit;True;Property;_FlowmapTex;FlowmapTex;4;0;Create;True;0;0;0;False;0;False;-1;ddcaa6cb05170b64c86ef89fca4559c7;0e55a84d3700d4e468e0963c55db013d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.NegateNode;220;-2080,1632;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;223;-2480,2208;Inherit;False;Constant;_Vector4;Vector 0;37;0;Create;True;0;0;0;False;0;False;-1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleSubtractOpNode;21;-2592,-896;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;270;-2736,2048;Inherit;False;258;DetailSize_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;269;-2752,2160;Inherit;False;257;DetailTexSpeed_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;184;-2704,928;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NegateNode;221;-2176,688;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;245;-2176,432;Inherit;False;244;FlowmapStrength_Ref;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;205;-2544,1120;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;287;-2224,-1856;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;290;-2560,-1584;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;292;-2016,-1952;Inherit;False;244;FlowmapStrength_Ref;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;305;-2512,-1264;Inherit;False;257;DetailTexSpeed_Ref;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;185;-1824,1632;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;222;-2288,2128;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;187;-2384,1888;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;23;-2400,-864;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;12;-2688,-656;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;246;-1936,1520;Inherit;False;244;FlowmapStrength_Ref;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;189;-2512,896;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;191;-1904,640;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;188;-2000,800;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;190;-2352,1056;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;7,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;293;-2368,-1616;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;294;-1760,-1872;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;295;-1856,-1712;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;300;-2208,-1456;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;7,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;1;-976,-176;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;192;-2128,1888;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0.3,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;193;-1680,1584;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;3;-880,96;Inherit;False;Property;_LerpAlpha;LerpAlpha;0;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;11;-2432,-656;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.3,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;-2192,-912;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;194;-2208,896;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.3,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;195;-1776,816;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;296;-2064,-1616;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.3,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;297;-1632,-1696;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;196;-1712,1888;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;237;-1371.035,729.6091;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;235;-880,288;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;243;-687.3892,229.9949;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;15;-2112,-704;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;197;-1616,864;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;302;-1472,-1648;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;80;-784,-1232;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;-1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;94;-480,-288;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;10;-656,-800;Inherit;True;Property;_Detail1;Detail1;1;0;Create;True;0;0;0;False;0;False;-1;370ba9a0460071147923c3e839c1d448;370ba9a0460071147923c3e839c1d448;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SamplerNode;238;-1163.035,713.6091;Inherit;True;Property;_Detail6;Detail1;1;0;Create;True;0;0;0;False;0;False;-1;370ba9a0460071147923c3e839c1d448;370ba9a0460071147923c3e839c1d448;True;0;False;white;Auto;False;Instance;10;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SamplerNode;198;-1408,1760;Inherit;True;Property;_Detail4;Detail1;1;0;Create;True;0;0;0;False;0;False;43;370ba9a0460071147923c3e839c1d448;370ba9a0460071147923c3e839c1d448;True;0;False;white;Auto;False;Instance;10;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleSubtractOpNode;236;-384,272;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;199;-1776,1008;Inherit;True;Property;_Detail5;Detail1;1;0;Create;True;0;0;0;False;0;False;43;370ba9a0460071147923c3e839c1d448;370ba9a0460071147923c3e839c1d448;True;0;False;white;Auto;False;Instance;10;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SamplerNode;77;-576,-1248;Inherit;True;Property;_Detail3;Detail1;1;0;Create;True;0;0;0;False;0;False;43;370ba9a0460071147923c3e839c1d448;370ba9a0460071147923c3e839c1d448;True;0;False;white;Auto;False;Instance;10;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SamplerNode;43;-1312,-1328;Inherit;True;Property;_Detail2;Detail1;1;0;Create;True;0;0;0;False;0;False;43;370ba9a0460071147923c3e839c1d448;370ba9a0460071147923c3e839c1d448;True;0;False;white;Auto;False;Instance;10;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RangedFloatNode;87;-80,-736;Inherit;False;Property;_DetailEdgeSize;DetailEdgeSize;11;0;Create;True;0;0;0;False;0;False;0;0;0;0.6;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;25;-320,-848;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;224;-944,1344;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;225;-912,1104;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;91;-272,-1088;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;88;144,-1056;Inherit;False;Property;_DetailStrength;DetailStrength;12;0;Create;True;0;0;0;False;0;False;1;1;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;263;174.6664,-591.2796;Inherit;False;DetailEdgeSize_Ref;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;79;-75.70508,-985.9315;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;226;-688,1200;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;304;456.4857,-1020.059;Inherit;False;DetailStrength_Ref;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;318;-621.3513,1671.026;Inherit;False;263;DetailEdgeSize_Ref;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;86;208,-896;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;228;-416,1296;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;319;-384,1200;Inherit;False;304;DetailStrength_Ref;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;84;512,-720;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;230;-112,1472;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;90;512,-592;Inherit;False;Property;_RightDetailColor;RightDetailColor;17;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;False;0;6;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.ColorNode;231;-112,1600;Inherit;False;Property;_LeftDetailColor;LeftDetailColor;18;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;2,2,2,0;True;False;0;6;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;89;768,-656;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;82;784,-832;Inherit;False;Constant;_Float0;Float 0;19;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;233;160,1360;Inherit;False;Constant;_Float1;Float 0;19;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;232;112,1504;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexColorNode;328;523.389,228.7801;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;324;832,-384;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;5;816,-192;Inherit;False;Property;_RightColor;RightColor;3;0;Create;True;0;0;0;True;0;False;0,0.2601228,1,0;0,0.2601228,1,1;False;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.ColorNode;6;496,400;Inherit;False;Property;_LeftColor;LeftColor;2;0;Create;True;0;0;0;False;0;False;1,0,0,0;1,0,0,1;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.StepOpNode;8;-560,-32;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0.82;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;29;960,-832;Inherit;True;Property;_UseDetail;UseDetail?;8;0;Create;True;0;0;0;False;0;False;0;1;1;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;234;384,1360;Inherit;True;Property;_UseDetail1;UseDetail?;8;0;Create;True;0;0;0;False;0;False;0;1;1;True;;Toggle;2;Key0;Key1;Reference;29;True;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;329;739.2849,316.1375;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;323;1120,-384;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;254;976,-1392;Inherit;False;Property;_BorderColor;BorderColor;14;0;Create;True;0;0;0;False;0;False;1,0.9729279,0,0;1,0.9729279,0,1;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.VertexColorNode;331;976,-1568;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;9;-256,-32;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;242;974.0493,374.3731;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;250;1200,-1152;Inherit;True;Property;_TexBorder;TexBorder;13;0;Create;True;0;0;0;False;0;False;-1;2f1e693ed09d0484e89a7b4b1de32225;2f1e693ed09d0484e89a7b4b1de32225;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleAddOpNode;83;1264,-400;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;330;1293.417,-1520.199;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;4;1648,-80;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;253;1440,-1344;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.BlendOpsNode;255;1696,-1232;Inherit;True;PinLight;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;256;2096,-256;Inherit;True;Property;_UseBorder;UseBorder?;15;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;327;2576,-272;Float;False;True;-1;3;AmplifyShaderEditor.MaterialInspector;0;3;S_UI_BarFill;5056123faa0c79b47ab6ad7e8bf059a4;True;Default;0;0;Default;2;True;True;2;5;False;;10;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;True;True;True;True;True;True;0;True;_ColorMask;False;False;False;False;False;False;True;True;True;0;True;_Stencil;255;True;_StencilReadMask;255;True;_StencilWriteMask;0;True;_StencilComp;0;True;_StencilOp;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;True;True;2;False;;True;0;True;_ColorMask;False;True;5;Queue=Transparent=Queue=0;IgnoreProjector=True;RenderType=Transparent=RenderType;PreviewType=Plane;CanUseSpriteAtlas=True;False;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;False;0;;0;0;Standard;0;0;1;True;False;;False;0
WireConnection;260;0;45;0
WireConnection;272;0;46;0
WireConnection;164;0;315;0
WireConnection;168;0;314;0
WireConnection;259;0;24;0
WireConnection;206;0;207;0
WireConnection;206;1;321;0
WireConnection;165;0;320;0
WireConnection;167;0;164;0
WireConnection;201;0;203;0
WireConnection;201;1;168;0
WireConnection;277;0;310;0
WireConnection;170;0;165;0
WireConnection;170;2;206;0
WireConnection;16;0;45;0
WireConnection;258;0;51;0
WireConnection;172;0;167;0
WireConnection;172;2;201;0
WireConnection;173;0;316;0
WireConnection;278;0;311;0
WireConnection;280;0;277;0
WireConnection;174;0;165;1
WireConnection;174;1;271;0
WireConnection;175;1;170;0
WireConnection;17;0;16;0
WireConnection;17;2;46;0
WireConnection;176;0;167;1
WireConnection;176;1;173;0
WireConnection;177;1;172;0
WireConnection;284;0;309;0
WireConnection;257;0;27;0
WireConnection;283;0;280;0
WireConnection;283;2;278;0
WireConnection;179;0;175;1
WireConnection;179;1;174;0
WireConnection;22;0;16;1
WireConnection;22;1;24;0
WireConnection;244;0;20;0
WireConnection;180;0;177;1
WireConnection;180;1;176;0
WireConnection;285;0;280;1
WireConnection;285;1;284;0
WireConnection;307;0;306;0
WireConnection;313;0;312;0
WireConnection;286;1;283;0
WireConnection;18;1;17;0
WireConnection;220;0;179;0
WireConnection;21;0;18;1
WireConnection;21;1;22;0
WireConnection;184;0;313;0
WireConnection;221;0;180;0
WireConnection;205;0;317;0
WireConnection;205;1;204;0
WireConnection;287;0;286;1
WireConnection;287;1;285;0
WireConnection;290;0;307;0
WireConnection;185;0;220;0
WireConnection;222;0;269;0
WireConnection;222;1;223;0
WireConnection;187;0;270;0
WireConnection;23;0;21;0
WireConnection;12;0;51;0
WireConnection;189;0;184;0
WireConnection;191;0;245;0
WireConnection;188;0;221;0
WireConnection;190;0;205;0
WireConnection;293;0;290;0
WireConnection;294;0;292;0
WireConnection;295;0;287;0
WireConnection;300;0;305;0
WireConnection;192;0;187;0
WireConnection;192;2;222;0
WireConnection;193;0;246;0
WireConnection;193;1;185;0
WireConnection;11;0;12;0
WireConnection;11;2;27;0
WireConnection;19;0;20;0
WireConnection;19;1;23;0
WireConnection;194;0;189;0
WireConnection;194;2;190;0
WireConnection;195;0;191;0
WireConnection;195;1;188;0
WireConnection;296;0;293;0
WireConnection;296;2;300;0
WireConnection;297;0;294;0
WireConnection;297;1;295;0
WireConnection;196;0;193;0
WireConnection;196;1;192;0
WireConnection;235;0;1;1
WireConnection;243;0;3;0
WireConnection;15;0;19;0
WireConnection;15;1;11;0
WireConnection;197;0;195;0
WireConnection;197;1;194;0
WireConnection;302;0;297;0
WireConnection;302;1;296;0
WireConnection;94;0;1;1
WireConnection;94;1;3;0
WireConnection;10;1;15;0
WireConnection;238;1;237;0
WireConnection;198;1;196;0
WireConnection;236;0;235;0
WireConnection;236;1;243;0
WireConnection;199;1;197;0
WireConnection;77;1;80;0
WireConnection;43;1;302;0
WireConnection;25;0;43;3
WireConnection;25;1;10;1
WireConnection;224;0;199;3
WireConnection;224;1;198;1
WireConnection;225;0;236;0
WireConnection;225;1;238;4
WireConnection;91;0;77;4
WireConnection;91;1;94;0
WireConnection;263;0;87;0
WireConnection;79;0;91;0
WireConnection;79;1;25;0
WireConnection;226;0;225;0
WireConnection;226;1;224;0
WireConnection;304;0;88;0
WireConnection;86;0;79;0
WireConnection;86;1;87;0
WireConnection;228;0;226;0
WireConnection;228;1;318;0
WireConnection;84;0;88;0
WireConnection;84;1;86;0
WireConnection;230;0;319;0
WireConnection;230;1;228;0
WireConnection;89;0;84;0
WireConnection;89;1;90;0
WireConnection;232;0;230;0
WireConnection;232;1;231;0
WireConnection;8;0;1;1
WireConnection;8;1;3;0
WireConnection;29;1;82;0
WireConnection;29;0;89;0
WireConnection;234;1;233;0
WireConnection;234;0;232;0
WireConnection;329;0;328;0
WireConnection;329;1;6;0
WireConnection;323;0;324;0
WireConnection;323;1;5;0
WireConnection;9;0;8;0
WireConnection;242;0;329;0
WireConnection;242;1;234;0
WireConnection;83;0;29;0
WireConnection;83;1;323;0
WireConnection;330;0;331;0
WireConnection;330;1;254;0
WireConnection;4;0;83;0
WireConnection;4;1;242;0
WireConnection;4;2;9;0
WireConnection;253;0;250;1
WireConnection;253;1;330;0
WireConnection;255;0;253;0
WireConnection;255;1;4;0
WireConnection;255;2;250;1
WireConnection;256;1;4;0
WireConnection;256;0;255;0
WireConnection;327;0;256;0
ASEEND*/
//CHKSM=C89B5F79BE26CD3779FFEC4D7B2F11AF83AD7B4E