using UnityEngine;

namespace RoBorg.MlpMagic
{
    /// <summary>
    /// Magic-only camera
    /// </summary>
    public class MaskCamera : MonoBehaviour
    {
        /// <summary>
        /// The magic gradient texture to use (the colour of the magic, how it fades)
        /// </summary>
        public Texture2D magicGradient;

        /// <summary>
        /// The final magic glow effect, ready to be added to the scene
        /// </summary>
        public RenderTexture finalGlow { get; private set; }

        /// <summary>
        /// The full scene's depth buffer
        /// </summary>
        public RenderTexture sceneDepthBuffer { get; private set; }

        /// <summary>
        /// The camera to render just the magic items
        /// </summary>
        public new Camera camera { get; private set; }

        /// <summary>
        /// The mask after it's been transformed (distorted)
        /// </summary>
        public RenderTexture transformedMaskTexture;

        /// <summary>
        /// The mask's depth buffer
        /// </summary>
        public RenderTexture maskDepthBuffer;

        /// <summary>
        /// Material to apply the transform
        /// </summary>
        public Material magicTransformMaterial;

        /// <summary>
        /// Material to apply the glow
        /// </summary>
        public Material magicGlowMaterial;

        /// <summary>
        /// The depth buffer of the magic-items-only scene (this camera)
        /// </summary>
        public Material depthBufferMaterial;

        /// <summary>
        /// Initialize the object, create the textures
        /// </summary>
        public void Init()
        {
            camera = GetComponent<Camera>();
            camera.targetTexture = finalGlow;
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = Color.black;
            camera.SetReplacementShader(Shader.Find("Hidden/MlpMagic/Replace"), "Magic");
            camera.depthTextureMode = DepthTextureMode.Depth;

            finalGlow = new RenderTexture(Screen.width, Screen.height, 32);
            sceneDepthBuffer = new RenderTexture(Screen.width, Screen.height, 32);
            transformedMaskTexture = new RenderTexture(Screen.width, Screen.height, 32);
            maskDepthBuffer = new RenderTexture(Screen.width, Screen.height, 32);

            magicTransformMaterial = new Material(Shader.Find("Hidden/MlpMagic/Transform"));
            magicGlowMaterial = new Material(Shader.Find("Hidden/MlpMagic/Glow"));
            depthBufferMaterial = new Material(Shader.Find("Hidden/MlpMagic/DepthBuffer"));

            magicGlowMaterial.SetTexture("_MagicGradientTex", magicGradient);
            magicGlowMaterial.SetTexture("_SceneDepthBuffer", sceneDepthBuffer);
            magicGlowMaterial.SetTexture("_MaskDepthBuffer", maskDepthBuffer);

            transformedMaskTexture.useMipMap = true;
        }

        /// <summary>
        /// Post-process the rendered image
        /// </summary>
        /// <param name="src">The source image</param>
        /// <param name="dest">The final image</param>
        private void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            // Distort the depth buffer (identically to the main texture) and save it
            Graphics.Blit(src, transformedMaskTexture, depthBufferMaterial);
            Graphics.Blit(transformedMaskTexture, maskDepthBuffer, magicTransformMaterial);

            // Distort the image then apply the glow, ready to be composited to the final image
            Graphics.Blit(src, transformedMaskTexture, magicTransformMaterial);
            Graphics.Blit(transformedMaskTexture, finalGlow, magicGlowMaterial);
        }
    }
}
