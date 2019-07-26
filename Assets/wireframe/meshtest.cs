using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class meshtest : MonoBehaviour
{
    // Start is called before the first frame update
    private MeshFilter meshfilter;
   
    void Start()
    {
        meshfilter = GetComponent<MeshFilter>();
        Vector3[] vertices = meshfilter.mesh.vertices;
        foreach(var vertex in vertices)
        {
            Debug.Log(vertex);
        }
    }

    // Update is called once per frame
    void Update()
    {
       
    }
}
