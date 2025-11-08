using Godot;
using System;

[Tool]
public partial class HingeDoorJacob : Node3D
{
	[Export]
	public float doorHeight;

	[Export]
	private MeshInstance3D hingeDoorMesh;
	[Export]
	private CollisionShape3D doorCollisionShape;
	
	private void _UpdateHingeDoorGeometry()
	{
		var doorMesh = hingeDoorMesh.Mesh as CylinderMesh;
		doorMesh.Height = doorHeight;
		hingeDoorMesh.Position = new Vector3(0, doorHeight/2, 0);
		var collisionMesh = doorCollisionShape.Shape as CylinderShape3D;
		collisionMesh.Height = doorHeight;
		doorCollisionShape.Position = new Vector3(0, doorHeight/2, 0);
	}
	public override void _Ready()
	{		
		_UpdateHingeDoorGeometry();
	}
	public override void _Process(double delta) {
		_UpdateHingeDoorGeometry();
	}
}
