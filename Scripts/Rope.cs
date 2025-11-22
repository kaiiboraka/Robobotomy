using Godot;
using System;

[Tool]
public partial class Rope : Climbable
{
	// --- Rope Shape ---
	[ExportGroup("Rope Shape")]
	[Export(PropertyHint.Range, "0.1,10.0,0.1,or_greater")]
	private float _length = 10.0f;
	public float Length
	{
		get => _length;
		set
		{
			_length = Mathf.Max(value, 0.1f);
			if (Engine.IsEditorHint())
				UpdateRopeGeometry();
		}
	}

	// --- Physics Parameters ---
	[ExportGroup("Physics Parameters")]
	[Export] public float Gravity = -100.0f;
	[Export] public float LaunchForce = 4.0f;
	[Export] public float AngularDampening = 0.5f;

	// --- Debug ---
	[ExportGroup("Physics Debugging")]
	[Export] public float AngularVelocity = 0.0f;

	// --- Rope Geometry ---
	private MeshInstance3D _ropeMesh;
	private Area3D _grabArea;
	private CollisionShape3D _grabShape;

	private float _angle = 0.0f;

	public override void _Ready()
	{
		_ropeMesh = GetNode<MeshInstance3D>("Rope Mesh");
		_grabArea = GetNode<Area3D>("Grabable Area");
		_grabShape = GetNode<CollisionShape3D>("Grabable Area/Grabable Shape");

		UpdateRopeGeometry();
	}

	public override void _PhysicsProcess(double delta)
	{
		float pivot = GrabPosition > 0.001f ? GrabPosition : _length;
		float angularAccel = (Gravity / pivot) * Mathf.Sin(_angle);

		AngularVelocity += angularAccel * (float)delta;
		_angle += AngularVelocity * (float)delta;

		UpdateRopeAngle();

		AngularVelocity *= 1 - AngularDampening * (float)delta;
	}

	// --------------------------------------------------------
	// ROPE GEOMETRY
	// --------------------------------------------------------
	private void UpdateRopeGeometry()
	{
		if (_ropeMesh == null || _grabShape == null)
			return;

		// Duplicate mesh
		var mesh = _ropeMesh.Mesh.Duplicate() as CylinderMesh;
		mesh.Height = _length;

		// Duplicate shape
		var shape = _grabShape.Shape.Duplicate() as BoxShape3D;
		shape.Size = new Vector3(shape.Size.X, _length + 0.5f, shape.Size.Z);

		// Positioning
		_ropeMesh.Position = new Vector3(0, -_length / 2f, 0);
		_grabArea.Position = new Vector3(0, -( _length + 0.5f ) / 2f, 0);

		// Apply
		_ropeMesh.Mesh = mesh;
		_grabShape.Shape = shape;
	}

	private void UpdateRopeAngle()
	{
		Rotation = new Vector3(Rotation.X, Rotation.Y, _angle);
	}

	// --------------------------------------------------------
	// INTERACTION LOGIC
	// --------------------------------------------------------
	public override void InteractWith(Node3D interactor)
	{
		if (interactor is not CharacterBody3D grabber)
			return;

		Vector3 distToRope = GlobalPosition - grabber.GlobalPosition;
		distToRope.Z = 0;

		GrabPosition = Mathf.Clamp(distToRope.Length(), LowerClimbLimit, Length - UpperClimbLimit);

		Vector3 ropeDir = distToRope.Normalized();
		Vector3 tangentDir = new Vector3(ropeDir.Y, -ropeDir.X, 0);
		float tangentSpeed = grabber.Velocity.Dot(tangentDir);
		
		AngularVelocity += tangentSpeed / GrabPosition;
	}

	public override void StopInteraction(Node3D interactor)
	{
		GrabPosition = 0.0f;
	}

	public override Vector3 JumpOff()
	{
		Vector3 tangent = new Vector3(Mathf.Cos(_angle), 0, 0);
		float tangentSpeed = AngularVelocity * GrabPosition;
		return tangent * tangentSpeed * LaunchForce;
	}

	public override Vector3 GetGrabPoint()
	{
		return new Vector3(
			GrabPosition * Mathf.Sin(_angle),
			-GrabPosition * Mathf.Cos(_angle),
			0
		) + GlobalPosition;
	}

	public override void Push(Vector3 dir, float force)
	{
		if (GrabPosition < 0.001f)
			return;

		Vector3 tangentDir = new Vector3(Mathf.Cos(_angle), -Mathf.Sin(_angle), 0);
		float tangentialForce = dir.Dot(tangentDir) * force;
		float angularAccel = tangentialForce / GrabPosition;

		AngularVelocity += angularAccel;
	}

	public override void Climb(Vector3 dir, float speed)
	{
		float dirSpeed =
			dir.Y < 0 ? ClimbSpeed :
			dir.Y > 0 ? SlideSpeed :
			0;

		GrabPosition += dir.Y * speed * dirSpeed;

		GrabPosition = Mathf.Clamp(GrabPosition, LowerClimbLimit, Length - UpperClimbLimit);
	}
}
