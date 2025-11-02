using Godot;
using System;

public partial class HingeDoorJacob : Node3D
{
	[Export]
	public float doorHeight;

	MeshInstance3D hingeDoorMesh;
	// questions to answer:
	// how do I procedurally create a mesh?
	// how do I get a reference to 'Hinge Door Mesh' in the same way the Rope does?
	// 
	private void _update_hinge_door_geometry()
	{
		//CylinderMesh hingeDoorMesh = hingeDoorMesh.mesh;
		//hingeDoorMesh.set_height(doorHeight);
	}
}
