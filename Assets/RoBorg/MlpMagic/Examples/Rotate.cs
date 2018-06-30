using UnityEngine;

namespace RoBorg.MlpMagic
{
    public class Rotate : MonoBehaviour
    {
        public Vector3 speed;

        private void Update()
        {
            transform.Rotate(new Vector3(speed.x * Time.deltaTime, speed.y * Time.deltaTime, speed.z * Time.deltaTime));
        }
    }
}
