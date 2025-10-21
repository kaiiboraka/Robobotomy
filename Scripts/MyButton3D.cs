using Godot;
using System;

public partial class MyButton3D : Area3D
{
	public override void _Ready()
	{
		Connect("body_entered", new Callable(this, nameof(OnBodyEntered)));
	}
	
	private void OnBodyEntered(Node3D body)
	{
		String ObjCollision = $"Collided with: {body.Name}";
		GD.Print(ObjCollision);
		// You can check the type or group of the 'body' here
		if (body is RigidBody3D rigidBody)
		{
			// Handle collision with a RigidBody3D
		}
	}
	
	public override void _Process(double delta)
	{
		
	}
	
	public override void _PhysicsProcess(double delta)
	{
		//physics logic stuffs
	}
}
