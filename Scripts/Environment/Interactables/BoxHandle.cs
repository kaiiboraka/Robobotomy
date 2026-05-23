using Godot;

[Tool]

public partial class BoxHandle : Interactable
{
	// -------------------------
	// EXPORTED VARIABLES
	// -------------------------
	[Export] public bool IsVertical { get; set; } = false;

	// -------------------------
	// ONREADY FIELDS
	// -------------------------
	private Generic6DofJoint3D grabJoint;
	private Box box;
	private MeshInstance3D meshInstance;
	private CollisionShape3D grabShape;

	// -------------------------
	// LIFECYCLE
	// -------------------------
	public override void _Ready()
	{
		grabJoint = GetNode<Generic6DofJoint3D>("Grab Joint");
		box = GetParent().GetParent() as Box;
		meshInstance = GetNode<MeshInstance3D>("Handle Mesh");
		grabShape = GetNode<CollisionShape3D>("Grabbable Area/Grabbable Shape");

		grabJoint.GlobalRotation = Vector3.Zero;
	}

	// -------------------------
	// INTERACTION
	// -------------------------
	public override void InteractWith(Node3D interactor)
	{
		if (interactor is not CharacterBody3D player)
			return;

		grabJoint.NodeA = box.GetPath();
		grabJoint.NodeB = player.GetPath();

		box.Grab(player);
	}

	public override void StopInteraction(Node3D interactor)
	{
		if (interactor is not CharacterBody3D player)
			return;

		grabJoint.NodeA = "";
		grabJoint.NodeB = "";

		box.StopGrab(player);
	}

	// -------------------------
	// GEOMETRY HELPERS
	// -------------------------
	public void SetGeometry(Vector3 size)
	{
		if (meshInstance.Mesh is BoxMesh originalMesh)
		{
			BoxMesh mesh = (BoxMesh)originalMesh.Duplicate();
			mesh.Size = size;
			meshInstance.Mesh = mesh;
		}
	}

	public void SetGrabShape(Vector3 size)
	{
		if (grabShape.Shape is BoxShape3D originalShape)
		{
			BoxShape3D shape = (BoxShape3D)originalShape.Duplicate();
			shape.Size = size;
			grabShape.Shape = shape;
		}
	}
}
