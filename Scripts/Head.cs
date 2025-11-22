using Godot;
using System;

public partial class Head : PlayerLimbs
{
	public const float PipeSpeed = 5.0f;
	
	public bool inPipe = false;

	
	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _PhysicsProcess(double delta)
	{
		
	}
	
	public void enterPipe() 
	{
		inPipe = true;
		MotionMode = 
	}
	
	public Vector3 pipeMovement() 
	{
		
	}
}
