using Godot;
using System;

public partial class RightArm : LeftArm, ISelectable
{
    //Inherits from LeftArm so that changes to one arm affect the other
    //You can override if you need to.
    public override void _Ready()
    {
        myType = ActualPlayer.LimbTypes.RightArm;
        amIsolated = false;
        phantomCamera = GetNode<Node3D>("PhantomCamera3D");
        jumpArea = GetNode<Area3D>("JumpArea");
        jumpArea.BodyEntered += OnHitFloor;
        jumpArea.BodyExited += OnLeaveFloor;
    }
}
