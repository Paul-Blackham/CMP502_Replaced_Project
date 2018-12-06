////////////////////////////////////////////////////////////////////////////////
// Filename: light.ps
////////////////////////////////////////////////////////////////////////////////


/////////////
// GLOBALS //
/////////////

Texture2D shaderTextures[2];
SamplerState SampleType;

cbuffer LightBuffer
{
	float4 ambientColor;
    float4 diffuseColor;
    float3 lightDirection;
	float specularPower;
    float4 specularColor;
};


//////////////
// TYPEDEFS //
//////////////
struct PixelInputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 viewDirection : TEXCOORD1;
	float3 tangent : TANGENT;
	float3 binormal : BINORMAL;
};


////////////////////////////////////////////////////////////////////////////////
// Pixel Shader
////////////////////////////////////////////////////////////////////////////////
float4 LightPixelShader(PixelInputType input) : SV_TARGET
{

	float4 textureColor;
	float4 bumpMap;
	float3 bumpNormal;
	float3 lightDir;
	float lightIntensity;
	float4 color;
	float3 reflection;
    float4 specular;

	//input.normal = normalize(input.normal);

	// Set the default output color to the ambient light value for all pixels.
	color = ambientColor;//float4(lightDirection.x, lightDirection.y, lightDirection.z, 1.0f);

	// Sample the pixel color from the texture using the sampler at this texture coordinate location.
	textureColor = shaderTextures[0].Sample(SampleType, input.tex);

	// Sample the pixel in the bump map.
	bumpMap = shaderTextures[1].Sample(SampleType, input.tex);

	// Expand the range of the normal value from (0, +1) to (-1, +1).
	bumpMap = (bumpMap * 2.0f) - 1.0f;

	// Calculate the normal from the data in the bump map.
	bumpNormal = (bumpMap.x * input.tangent) + (bumpMap.y * input.binormal) + (bumpMap.z * input.normal);

	// Normalize the resulting bump normal.
	bumpNormal = normalize(bumpNormal);
	
	// Initialize the specular color.
    specular = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// Invert the light direction for calculations.
	lightDir = -lightDirection;

    // Calculate the amount of light on this pixel.
    lightIntensity = saturate(dot(bumpNormal, lightDir));

    // Determine the final amount of diffuse color based on the diffuse color combined with the light intensity.

	if(lightIntensity > 0.0f)
	{
		// Determine the final diffuse color based on the diffuse color and the amount of light intensity.
		color += (diffuseColor * lightIntensity);

		// Saturate the ambient and diffuse color.
        color = saturate(color);

		// Calculate the reflection vector based on the light intensity, normal vector, and light direction.
		reflection = normalize(2 * lightIntensity * bumpNormal - lightDir);

		// Determine the amount of specular light based on the reflection vector, viewing direction, and specular power.
		specular = specularColor * pow(saturate(dot(reflection, input.viewDirection)), specularPower);
	}

	// Multiply the texture pixel and the final diffuse color to get the final pixel color result.
	color = saturate(color * textureColor);

	// Add the specular component last to the output color.
    color = saturate(color + specular);

    return color;
}
