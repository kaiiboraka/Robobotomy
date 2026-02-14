using Godot;
using System;

// Hinge Door Specs:
// this is a Hinge object
// the level designer can do the following:
// attach a mesh that will rotate around the Hinge
// define angle constraints (display debug lines in viewport?)
// set the size of the hinge?

[Tool]
public partial class Hinge : Node3D
{
	[Export]
	public float UpperAngle { get => upperAngle;  set {
			upperAngle = value;
		}
	}
	private float upperAngle;
	[Export]
	public float LowerAngle { get => lowerAngle; set
		{
			lowerAngle = value;
		}
	}
	private float lowerAngle;
	[Export]
	public float ArmLength { get => armLength; set
		{
			armLength = value;
			UpdateArmCollision();
			UpdateArmMesh();
		}
	}
	private float armLength;
	[Export]
	public float ArmWidth { get => armWidth; set
		{
			armWidth = value;
			UpdateArmCollision();
		}
	}
	private float armWidth;
	[Export]
	public float Depth { get => depth; set
		{
			depth = value;
			UpdateBaseMesh();
			UpdateBaseCollision();
			UpdateArmCollision();
		}
	}
	private float depth;
	[Export]
	public float BaseRadius { get => baseRadius; set
		{
			baseRadius = value;
			UpdateBaseMesh();
			UpdateArmMesh();
			UpdateBaseCollision();
		}
	}
	private float baseRadius;

	[Export]
	public Mesh ArmMesh { get => armMesh; set
		{
			armMesh = value;
			UpdateArmMesh();
		}
	}
	private Mesh armMesh;	
	
	private MeshInstance3D armMeshInstance;
	private MeshInstance3D baseMeshInstance;
	private CollisionShape3D baseCollisionShape;
	private CollisionShape3D armCollisionShape;


	public override void _Ready()
	{
		UpdateArmMesh();
		UpdateBaseMesh();
		UpdateBaseCollision();
	}
	private void UpdateArmMesh()
	{
		armMeshInstance = GetNode<MeshInstance3D>("%HingeArmMesh");
		if(armMesh != null) {
			armMeshInstance.Mesh = armMesh;
			armMeshInstance.Position = new Vector3(0, BaseRadius-armLength/2, 0);
		}
	}
	private void UpdateBaseMesh()
	{
		baseMeshInstance = GetNode<MeshInstance3D>("%HingeBaseMesh");
		CylinderMesh baseMesh = baseMeshInstance.Mesh as CylinderMesh;
		if(baseMesh != null) {
			baseMesh.TopRadius = BaseRadius;
			baseMesh.BottomRadius = BaseRadius;
			baseMesh.Height = Depth;
		}
		baseMeshInstance.Mesh = baseMesh;
	}
	private void UpdateBaseCollision()
	{
		baseCollisionShape = GetNode<CollisionShape3D>("%HingeBaseCollision");
		CylinderShape3D shape = baseCollisionShape.Shape as CylinderShape3D;
		if (shape != null)
		{
			shape.Radius = BaseRadius;
			shape.Height = Depth;
		}
		baseCollisionShape.Shape = shape;
	}
	private void UpdateArmCollision()
	{
		armCollisionShape = GetNode<CollisionShape3D>("%HingeArmCollision");
		BoxShape3D shape = armCollisionShape.Shape as BoxShape3D;
		if(shape != null)
		{
			shape.Size = new Vector3(ArmWidth, ArmLength, Depth);
			armCollisionShape.Position = new Vector3(0, ArmLength/2, 0);
		}
		armCollisionShape.Shape = shape;
	}
}
