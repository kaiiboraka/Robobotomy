using Godot;
using System;

public partial class Head : RigidBody3D, ISelectable
{
    //ISelectable
    public bool amIsolated { get; set; }
    public ActualPlayer.LimbTypes myType{get;set;}
    public bool amSelected {get;set;}

    //Movement
    [Export] private int speed = 3;
    private int jumpHeight = 0;
    private int strength = 0;
    private Node3D phantomCamera;
    private bool isGrounded;
    [Export]private int groundContacts;
    private Area3D jumpArea;
    

    //Ready
    public override void _Ready()
    {
        myType = ActualPlayer.LimbTypes.Head;
        amIsolated = false;
        phantomCamera = GetNode<Node3D>("PhantomCamera3D");
        jumpArea = GetNode<Area3D>("JumpArea");
        jumpArea.BodyEntered += OnHitFloor;
        jumpArea.BodyExited += OnLeaveFloor;
    }

    //ISelectable
    public ISelectable OnSelect()
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
    public void Deselect()
    {
        phantomCamera.Call("set_priority", 0);
    }

    public void OnConnect(Vector3 newPosition, IHub parent)
    {
        Deselect();
        Freeze = true;
        Position = newPosition;
    }

    public void OnDeconnect(IHub parent)
    {
        Freeze = false;
    }

    public void ConnectedBehavior()
    {
        
    }

    //Movement

    public void MoveMe()
    {
        Movement.MoveMe(this, isGrounded, speed, 1);
    }

    public void OnHitFloor(Node3D body)
    {
        isGrounded = Movement.OnHitFloor(body, groundContacts);
    }

    public void OnLeaveFloor(Node3D body)
    {
        isGrounded = Movement.OnLeaveFloor(body, groundContacts);
    }
}
