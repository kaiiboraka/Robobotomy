using Godot;
using System;

public partial class RightLeg : LeftLeg, ISelectable
{
    //Inherits from LeftLeg so that changes to one leg affect the other.
    //You can override if you need to.
    public override void _Ready()
    {
        myType = ActualPlayer.LimbTypes.RightLeg;
        amIsolated = false;
        phantomCamera = GetNode<Node3D>("PhantomCamera3D");
        jumpArea = GetNode<Area3D>("JumpArea");
        jumpArea.BodyEntered += OnHitFloor;
        jumpArea.BodyExited += OnLeaveFloor;
    }
}
