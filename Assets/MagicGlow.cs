using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode] // todo delete
public class MagicGlow : MonoBehaviour
{
    public Color color;
    public float lerpFactor = 10;

    private List<Material> materials = new List<Material>();
    private Color currentColor;
    private Color targetColor;

    private void Start()
    {
        var renderers = GetComponentsInChildren<Renderer>();

        foreach (var renderer in renderers)
        {
            materials.AddRange(renderer.materials);
        }

        Enable(); // TODO delete
    }

    private void Enable()
    {
        targetColor = color;
    }

    private void Disable()
    {
        targetColor = Color.black;
    }

    /// <summary>
    /// Loop over all cached materials and update their color, disable self if we reach our target color.
    /// </summary>
    private void Update()
    {
        currentColor = Color.Lerp(currentColor, targetColor, Time.deltaTime * lerpFactor);

        for (int i = 0; i < materials.Count; i++)
        {
            materials[i].SetColor("_GlowColor", currentColor);
        }

        if (currentColor.Equals(targetColor))
        {
            // TODO enabled = false;
        }
    }
}
