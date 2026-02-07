using Godot;
using System;

public partial class LeftArm : RigidBody3D, ISelectable
{
    //ISelectable
    public virtual bool amIsolated { get; set; }

    public ActualPlayer.LimbTypes myType {get;set;}
    public bool amSelected {get;set;}

    //Movement
    [Export] protected int speed = 3;
    protected int jumpHeight = 0;
    protected int strength = 0;
    protected Node3D phantomCamera;
    protected bool isGrounded;
    [Export]protected int groundContacts;
    protected Area3D jumpArea;

    //Ready
    public override void _Ready()
    {
        myType = ActualPlayer.LimbTypes.LeftArm;
        amIsolated = false;
        phantomCamera = GetNode<Node3D>("PhantomCamera3D");
        jumpArea = GetNode<Area3D>("JumpArea");
        jumpArea.BodyEntered += OnHitFloor;
        jumpArea.BodyExited += OnLeaveFloor;
    }

    //ISelectable
    public virtual ISelectable OnSelect()
    {
        if (amIsolated)
        {
            Freeze = false;
            phantomCamera.Call("set_priority", 1);
            return this;
        }
        else
        {
            GetParent<ISelectable>().OnSelect();
            return GetParent<ISelectable>();
        }
    }
    public virtual void Deselect()
    {
        phantomCamera.Call("set_priority", 0);
    }

    public virtual void ConnectedBehavior()
    {
        
    }

    public virtual void OnConnect(Vector3 newPosition, IHub parent)
    {
        Deselect();
        Freeze = true;
        Position = newPosition;
        parent.numArms += 1;
    }

    public virtual void OnDeconnect(IHub parent)
    {
        Freeze = false;
        parent.numArms -= 1;
    }

    //Movement

    public virtual void MoveMe()
    {
        Movement.MoveMe(this, isGrounded, speed, 1);
    }

    public virtual void OnHitFloor(Node3D body)
    {
        isGrounded = Movement.OnHitFloor(body, groundContacts);
    }

    public virtual void OnLeaveFloor(Node3D body)
    {
        isGrounded = Movement.OnLeaveFloor(body, groundContacts);
    }
}
