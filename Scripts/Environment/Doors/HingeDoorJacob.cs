using Godot;
using System;

[Tool]
public partial class HingeDoorJacob : Node3D
{
	[Export]
	public float doorHeight;
	[Export]
	public float doorRadius;
	[Export]
	private MeshInstance3D hingeDoorMesh;
	[Export]
	private CollisionShape3D doorCollisionShape;
	
	private void _UpdateHingeDoorGeometry()
	{
		var doorMesh = hingeDoorMesh.Mesh as CylinderMesh;
		doorMesh.Height = doorHeight;
		doorMesh.TopRadius = doorRadius;
		doorMesh.BottomRadius = doorRadius;
		hingeDoorMesh.Position = new Vector3(0, doorHeight/2, 0);
		
		var collisionMesh = doorCollisionShape.Shape as CylinderShape3D;
		collisionMesh.Height = doorHeight;
		collisionMesh.Radius = doorRadius;
		doorCollisionShape.Position = new Vector3(0, doorHeight/2, 0);
	}

	public override void _Ready()
	{		
		_UpdateHingeDoorGeometry();
	}
	public override void _Process(double delta) {
		_UpdateHingeDoorGeometry();
		//this.ApplyCentralForce(new Vector3(1, 0, 0));
	}
}
