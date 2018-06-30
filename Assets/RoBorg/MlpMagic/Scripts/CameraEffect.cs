using UnityEngine;

namespace RoBorg.MlpMagic
{
    /// <summary>
    /// Magic effect main camera script
    /// </summary>
    public class CameraEffect : MonoBehaviour
    {
        /// <summary>
        /// The camera that renders only magic items
        /// </summary>
        public MaskCamera maskCamera;

        /// <summary>
        /// Material to use the DepthBuffer shader
        /// </summary>
        private Material depthBufferMaterial;

        /// <summary>
        /// Matieral to use the Composite shader
        /// </summary>
        private Material compositeMaterial;

        /// <summary>
        /// Initialisation
        /// </summary>
        private void OnEnable()
        {
            var camera = GetComponent<Camera>();

            camera.depthTextureMode = DepthTextureMode.Depth;

            compositeMaterial = new Material(Shader.Find("Hidden/MlpMagic/Composite"));
            depthBufferMaterial = new Material(Shader.Find("Hidden/MlpMagic/DepthBuffer"));

            // Initialise the maskCamera before we assign it's outlineTexture to our material
            maskCamera.Init();

            compositeMaterial.SetTexture("_MagicTex", maskCamera.finalGlow);
        }

        /// <summary>
        /// Post-process the rendered image
        /// </summary>
        /// <param name="src">The source image</param>
        /// <param name="dest">The final image</param>
        private void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            // Save the depth buffer
            Graphics.Blit(src, maskCamera.sceneDepthBuffer, depthBufferMaterial);

            // Render the magic effect
            maskCamera.camera.Render();

            // Composite the magic onto the scene
            Graphics.Blit(src, dest, compositeMaterial);
        }
    }
}
