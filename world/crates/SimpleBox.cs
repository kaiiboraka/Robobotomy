using Godot;
using System;

public partial class SimpleBox : RigidBody3D,IWeighted
{
	[Export] public float Weight { get; set; } = 5.0f;
}
