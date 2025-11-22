using Godot;
using System.Collections.Generic;

[Tool]
public partial class Ladder : Climbable
{
	private static readonly PackedScene RungScene =
		GD.Load<PackedScene>("uid://3l8c2up5trrm");

	// ───────────────────────────────────────────────
	// EXPORTS — SHAPE PROPERTIES
	// ───────────────────────────────────────────────

	private float _length = 10.0f;
	[Export(PropertyHint.Range, "0.1,10.0,0.1,or_greater")]
	public float Length
	{
		get => _length;
		set
		{
			_length = Mathf.Max(0.1f, value);
			if (IsInsideTree())
				SetLength();
		}
	}

	private float _width = 1.0f;
	[Export(PropertyHint.Range, "0.1,2.0,0.05,or_greater")]
	public float Width
	{
		get => _width;
		set
		{
			_width = Mathf.Max(0.1f, value);
			if (IsInsideTree())
				SetWidth();
		}
	}

	private float _poleWidth = 0.1f;
	[Export(PropertyHint.Range, "0.001,0.5,0.001,or_greater")]
	public float PoleWidth
	{
		get => _poleWidth;
		set
		{
			_poleWidth = Mathf.Max(0.01f, value);
			if (IsInsideTree())
				SetPoleWidth();
		}
	}

	// ───────────────────────────────────────────────
	// EXPORTS — RUNG PARAMETERS
	// ───────────────────────────────────────────────

	private int _rungCount = 10;
	[Export(PropertyHint.Range, "0,99,1,or_greater")]
	public int RungCount
	{
		get => _rungCount;
		set
		{
			_rungCount = Mathf.Max(0, value);
			if (IsInsideTree())
				CalculateDensity();
		}
	}

	private float _rungWidth = 0.05f;
	[Export(PropertyHint.Range, "0.001,0.4,0.001,or_greater")]
	public float RungWidth
	{
		get => _rungWidth;
		set
		{
			_rungWidth = Mathf.Max(0.01f, value);
			if (IsInsideTree())
				SetRungGeometry();
		}
	}

	private float _topRungGap = 0.1f;
	[Export(PropertyHint.Range, "0.0,1.0,0.05,or_greater")]
	public float TopRungGap
	{
		get => _topRungGap;
		set
		{
			_topRungGap = Mathf.Max(0.0f, value);
			if (IsInsideTree())
				CalculateDensity();
		}
	}

	private float _bottomRungGap = 0.1f;
	[Export(PropertyHint.Range, "0.0,1.0,0.05,or_greater")]
	public float BottomRungGap
	{
		get => _bottomRungGap;
		set
		{
			_bottomRungGap = Mathf.Max(0.0f, value);
			if (IsInsideTree())
				CalculateDensity();
		}
	}

	// ───────────────────────────────────────────────
	// ONREADY EQUIVALENTS
	// ───────────────────────────────────────────────

	private MeshInstance3D _leftPole;
	private MeshInstance3D _rightPole;
	private CylinderMesh _leftPoleMesh;
	private CylinderMesh _rightPoleMesh;

	private CollisionShape3D _grabAreaShape;
	private BoxShape3D _grabBoxShape;

	private Node3D _rungContainer;

	private readonly List<LadderRung> _rungs = new();
	private float _rungDensity = 1.0f;


	public override void _Ready()
	{
		_leftPole = GetNode<MeshInstance3D>("Ladder Pole Left");
		_rightPole = GetNode<MeshInstance3D>("Ladder Pole Right");

		_leftPoleMesh = (CylinderMesh)_leftPole.Mesh.Duplicate();
		_rightPoleMesh = (CylinderMesh)_rightPole.Mesh.Duplicate();

		_leftPole.Mesh = _leftPoleMesh;
		_rightPole.Mesh = _rightPoleMesh;

		_grabAreaShape = GetNode<CollisionShape3D>("Grabable Area/Grabable Shape");
		_grabBoxShape = (BoxShape3D)_grabAreaShape.Shape.Duplicate();

		_grabAreaShape.Shape = _grabBoxShape;

		_rungContainer = GetNode<Node3D>("Rungs");

		// Only apply geometry updates during runtime.
		if (!Engine.IsEditorHint())
		{
			SetLength();
			SetWidth();
			SetPoleWidth();
		}
	}

	// ───────────────────────────────────────────────
	// CLIMBABLE IMPLEMENTATION
	// ───────────────────────────────────────────────

	public override void InteractWith(Node3D interactor)
	{
		if (interactor is not CharacterBody3D grabber)
			return;

		Vector3 dist = GlobalPosition - grabber.GlobalPosition;
		dist.Z = 0;

		GrabPosition = dist.Length();
	}

	public override void StopInteraction(Node3D interactor)
	{
		GrabPosition = 0.0f;
	}

	public override Vector3 GetGrabPoint()
	{
		return new Vector3(
			GlobalPosition.X,
			GlobalPosition.Y + Mathf.Clamp(GrabPosition, LowerClimbLimit, Length - UpperClimbLimit),
			0
		);
	}

	public override void Climb(Vector3 dir, float speed)
	{
		float dirSpeed = dir.Y < 0 ? ClimbSpeed : (dir.Y > 0 ? SlideSpeed : 0);
		GrabPosition -= dir.Y * speed * dirSpeed;
		GrabPosition = Mathf.Clamp(GrabPosition, LowerClimbLimit, Length - UpperClimbLimit);
	}

	public override Vector3 JumpOff() => Vector3.Zero;

	public override void Push(Vector3 dir, float force) { }


	// ───────────────────────────────────────────────
	// GEOMETRY + RUNG CREATION
	// ───────────────────────────────────────────────

	private void SetLength()
	{
		_leftPoleMesh.Height = Length;
		_rightPoleMesh.Height = Length;

		_leftPole.Position = new Vector3(_leftPole.Position.X, Length / 2f, 0);
		_rightPole.Position = new Vector3(_rightPole.Position.X, Length / 2f, 0);

		_grabBoxShape.Size = new Vector3(Width, Length + 0.5f, 1.0f);
		_grabAreaShape.Position = new Vector3(0, (Length + 0.5f) / 2f, 0);

		CalculateDensity();
	}

	private void SetWidth()
	{
		_leftPole.Position = new Vector3(-(Width / 2f), _leftPole.Position.Y, 0);
		_rightPole.Position = new Vector3(Width / 2f, _rightPole.Position.Y, 0);

		_grabBoxShape.Size = new Vector3(Width, Length + 0.5f, 1.0f);

		SetRungGeometry();
	}

	private void SetPoleWidth()
	{
		_leftPoleMesh.BottomRadius = PoleWidth;
		_leftPoleMesh.TopRadius = PoleWidth;
		_rightPoleMesh.BottomRadius = PoleWidth;
		_rightPoleMesh.TopRadius = PoleWidth;

		SetRungGeometry();
	}

	private void CalculateDensity()
	{
		_rungDensity =
			(Length - TopRungGap - BottomRungGap) / (Mathf.Max(RungCount, 2) - 1);

		SetRungs();
	}

	private void SetRungs()
	{
		foreach (var rung in _rungs)
			rung.QueueFree();
		_rungs.Clear();

		for (int i = 0; i < RungCount; i++)
		{
			var newRung = RungScene.Instantiate<LadderRung>();
			_rungContainer.AddChild(newRung);

			if (Engine.IsEditorHint())
				newRung.Owner = GetTree().EditedSceneRoot;

			_rungs.Add(newRung);
		}

		SetRungSpacing();
	}

	private void SetRungSpacing()
	{
		for (int i = 0; i < _rungs.Count; i++)
		{
			var rung = _rungs[i];
			rung.Position = new Vector3(
				rung.Position.X,
				BottomRungGap + (_rungDensity * i),
				0
			);
		}
	}

	private void SetRungGeometry()
	{
		foreach (var rung in _rungs)
		{
			rung.UpdateGeometry(
				Width - (PoleWidth / 2f),
				RungWidth
			);
		}
	}
}
