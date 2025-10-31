using Godot;
using System;

public partial class HingeDoorJacob : Node3D
{
    [Export]
    public float doorHeight;

    [Export]
    private MeshInstance3D hingeDoorMesh;
    // questions to answer:
    // how do I procedurally create a mesh?
    // how do I get a reference to 'Hinge Door Mesh' in the same way the Rope does?
    // 
    private void _UpdateHingeDoorGeometry()
    {
        var doorMesh = hingeDoorMesh.Mesh as CylinderMesh;
        doorMesh.Height = doorHeight;
    }
    public override void _Ready()
    {
        _UpdateHingeDoorGeometry();
    }
}
