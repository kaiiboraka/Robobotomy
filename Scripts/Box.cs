using Godot;
using System;
using System.Collections.Generic;

[Tool] 

public partial class Box : RigidBody3D
{
	// -------------------------
	// ENUM + PRESETS
	// -------------------------
	public enum SizePreset { Small, Medium, Large }

	private static readonly Vector4 SMALL_PRESET  = new Vector4(1, 1, 1, 1);
	private static readonly Vector4 MEDIUM_PRESET = new Vector4(2, 2, 2, 2);
	private static readonly Vector4 LARGE_PRESET  = new Vector4(3, 3, 3, 3);

	private static readonly Dictionary<SizePreset, Vector4> PRESETS =
		new()
		{
			{ SizePreset.Small, SMALL_PRESET },
			{ SizePreset.Medium, MEDIUM_PRESET },
			{ SizePreset.Large, LARGE_PRESET },
		};

	// -------------------------
	// EXPORTED PROPERTIES
	// -------------------------

	[ExportGroup("Physics Attributes")]
	private SizePreset _sizePreset = SizePreset.Small;
	[Export]
	public SizePreset sizePreset
	{
		get => _sizePreset;
		set
		{
			_sizePreset = value;
			if (Engine.IsEditorHint())
				SetPreset();
		}
	}

	private Vector3 _boxSize = new Vector3(1, 1, 1);
	[Export]
	public Vector3 boxSize
	{
		get => _boxSize;
		set
		{
			_boxSize = value;
			if (Engine.IsEditorHint())
				SetGeometry();
		}
	}

	private float _weight = 1f;
	[Export]
	public float weight
	{
		get => _weight;
		set
		{
			_weight = value;
			if (Engine.IsEditorHint())
				SetWeight();
		}
	}

	private bool _staticBox = false;
	[Export]
	public bool staticBox
	{
		get => _staticBox;
		set
		{
			_staticBox = value;
			if (Engine.IsEditorHint())
				SetStatic();
		}
	}


	[ExportGroup("Handles")]
	private bool _leftHandle = false;
	[Export] public bool leftHandle
	{
		get => _leftHandle;
		set { _leftHandle = value; if (Engine.IsEditorHint()) SetHandles(); }
	}

	private bool _rightHandle = false;
	[Export] public bool rightHandle
	{
		get => _rightHandle;
		set { _rightHandle = value; if (Engine.IsEditorHint()) SetHandles(); }
	}

	private bool _topHandle = false;
	[Export] public bool topHandle
	{
		get => _topHandle;
		set { _topHandle = value; if (Engine.IsEditorHint()) SetHandles(); }
	}

	private bool _bottomHandle = false;
	[Export] public bool bottomHandle
	{
		get => _bottomHandle;
		set { _bottomHandle = value; if (Engine.IsEditorHint()) SetHandles(); }
	}

	// -------------------------
	// READ ONLY
	// -------------------------
	[ExportGroup("Read Only")]
	private Handle[] handleArray;

	private MeshInstance3D meshInstance;
	private CollisionShape3D collisionShape;

	private CharacterBody3D grabber = null;
	private Vector3 grabberOffset = Vector3.Zero;
	private bool verticalGrab = false;


	// -------------------------
	// LIFECYCLE
	// -------------------------
	public override void _Ready()
	{
		// Onready equivalents
		meshInstance = GetNode<MeshInstance3D>("MeshInstance3D");
		collisionShape = GetNode<CollisionShape3D>("Collision Shape");

		handleArray = new Handle[]
		{
			GetNode<Handle>("Handles/Left Handle"),
			GetNode<Handle>("Handles/Right Handle"),
			GetNode<Handle>("Handles/Top Handle"),
			GetNode<Handle>("Handles/Bottom Handle"),
		};

		SetGeometry();
		SetWeight();
		SetStatic();
		SetHandles();
	}


	// -------------------------
	// PUBLIC METHODS
	// -------------------------
	public void Grab(CharacterBody3D player)
	{
		player.Call("SetCarryWeight", weight);
		AxisLockLinearX = false;
	}

	public void StopGrab(CharacterBody3D player)
	{
		player.Call("SetCarryWeight", 0.0f);
		SetStatic();
	}


	// -------------------------
	// PRESET APPLICATION
	// -------------------------
	private void SetPreset()
	{
		Vector4 preset = PRESETS[sizePreset];

		boxSize = new Vector3(preset.X, preset.Y, preset.Z);
		weight = preset.W;

		SetGeometry();
		SetWeight();
	}


	// -------------------------
	// GEOMETRY UPDATE
	// -------------------------
	private void SetGeometry()
	{
		if (meshInstance == null || collisionShape == null)
			return;

		if (meshInstance.Mesh is BoxMesh originalMesh)
		{
			BoxMesh mesh = (BoxMesh)originalMesh.Duplicate();
			mesh.Size = boxSize;
			meshInstance.Mesh = mesh;
		}

		if (collisionShape.Shape is BoxShape3D originalShape)
		{
			BoxShape3D shape = (BoxShape3D)originalShape.Duplicate();
			shape.Size = boxSize;
			collisionShape.Shape = shape;
		}

		SetHandles();
	}


	// -------------------------
	// WEIGHT UPDATE
	// -------------------------
	private void SetWeight()
	{
		Mass = weight;
	}


	// -------------------------
	// STATIC/AXIS LOCK UPDATE
	// -------------------------
	private void SetStatic()
	{
		AxisLockLinearX = staticBox;
		AxisLockLinearY = false;
		AxisLockLinearZ = true;

		AxisLockAngularX = staticBox;
		AxisLockAngularY = staticBox;
		AxisLockAngularZ = true;
	}


	// -------------------------
	// HANDLE UPDATE
	// -------------------------
	private void SetHandles()
	{
		if (handleArray == null || handleArray.Length == 0)
			return;

		bool[] handleFlags = { leftHandle, rightHandle, topHandle, bottomHandle };

		for (int i = 0; i < 4; i++)
		{
			Handle handle = handleArray[i];
			bool active = handleFlags[i];

			if (active)
			{
				handle.ProcessMode = Node.ProcessModeEnum.Inherit;
				handle.Visible = true;

				if (i == 0) // Left
				{
					handle.SetGeometry(new Vector3(Mathf.Max(boxSize.Y - 0.5f, 0.1f), 0.1f, 0.1f));
					handle.SetGrabShape(new Vector3(Mathf.Max(boxSize.Y - 0.2f, 0.1f), 0.8f, 0.8f));
					handle.Position = new Vector3(-(boxSize.X / 2 + 0.25f), handle.Position.Y, handle.Position.Z);
				}
				else if (i == 1) // Right
				{
					handle.SetGeometry(new Vector3(Mathf.Max(boxSize.Y - 0.5f, 0.1f), 0.1f, 0.1f));
					handle.SetGrabShape(new Vector3(Mathf.Max(boxSize.Y - 0.2f, 0.1f), 0.8f, 0.8f));
					handle.Position = new Vector3(boxSize.X / 2 + 0.25f, handle.Position.Y, handle.Position.Z);
				}
				else if (i == 2) // Top
				{
					handle.SetGeometry(new Vector3(Mathf.Max(boxSize.X - 0.5f, 0.1f), 0.1f, 0.1f));
					handle.SetGrabShape(new Vector3(Mathf.Max(boxSize.X - 0.2f, 0.1f), 0.8f, 0.8f));
					handle.Position = new Vector3(handle.Position.X, boxSize.Y / 2 + 0.25f, handle.Position.Z);
				}
				else // Bottom
				{
					handle.SetGeometry(new Vector3(Mathf.Max(boxSize.X - 0.5f, 0.1f), 0.1f, 0.1f));
					handle.SetGrabShape(new Vector3(Mathf.Max(boxSize.X - 0.2f, 0.1f), 0.8f, 0.8f));
					handle.Position = new Vector3(handle.Position.X, -(boxSize.Y / 2 + 0.25f), handle.Position.Z);
				}
			}
			else
			{
				handle.ProcessMode = Node.ProcessModeEnum.Disabled;
				handle.Visible = false;
			}
		}
	}
}
