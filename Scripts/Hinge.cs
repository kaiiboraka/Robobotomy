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
		}
	}
	private float armLength;
	[Export]
	public float ArmWidth { get => armWidth; set
		{
			armWidth = value;
		}
	}
	private float armWidth;
	[Export]
	public float Depth { get => depth; set
		{
			depth = value;
		}
	}
	private float depth;
	[Export]
	public float BaseRadius { get => baseRadius; set
		{
			baseRadius = value;
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
	private CollisionShape3D doorCollisionShape;


	public override void _Ready()
	{
		UpdateArmMesh();
	}
	private void UpdateArmMesh()
	{
		armMeshInstance = GetNode<MeshInstance3D>("%HingeArmMesh");
		if(armMesh != null) {
			armMeshInstance.Mesh = armMesh;
		}
	}

}
