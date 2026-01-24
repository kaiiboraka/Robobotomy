using Godot;
using System;

[Tool]
public partial class HingeDoorJacob : Node3D
{
    [Export]
    public float DoorHeight
    {
        get => DoorHeight; set
        {
            _UpdateHingeDoorGeometry();
        }
    }
    [Export]
    public float DoorRadius { get; set; }
    [Export]
    public float UpperAngle { get; set; }
    [Export]
    public float LowerAngle { get; set; }

    private MeshInstance3D _hingeDoorMesh;

    private Mesh doorMesh;
    [Export]
    public Mesh DoorMesh
    {
        get => doorMesh;
        set
        {
            doorMesh = value;
            if (_hingeDoorMesh != null)
            {
                _UpdateHingeDoorGeometry();
            }
        }
    }

    [Export]
    private CollisionShape3D doorCollisionShape;

    private void _UpdateHingeDoorGeometry()
    {
        if (_hingeDoorMesh == null)
        {
            GD.PrintErr("No Hinge Door Instance set!");
            return;
        }
        _hingeDoorMesh.Mesh = doorMesh;

        var collisionMesh = doorCollisionShape.Shape as CylinderShape3D;
        collisionMesh.Height = DoorHeight;
        collisionMesh.Radius = DoorRadius;
        doorCollisionShape.Position = new Vector3(0, DoorHeight / 2, 0);
    }

    public override void _EnterTree()
    {
        if (!Engine.IsEditorHint()) return;
        GetComponents();
    }

    public override void _Ready()
    {
        GetComponents();

        _UpdateHingeDoorGeometry();
    }

    // public override void _Process(double delta)
    // {
    // 	_UpdateHingeDoorGeometry();
    // 	//this.ApplyCentralForce(new Vector3(1, 0, 0));
    // }

    private void GetComponents()
    {
        GD.Print("Getting Components");

        _hingeDoorMesh ??= GetNode<MeshInstance3D>("%MeshInstance3D");
    }
}
