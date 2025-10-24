using Godot;
using System;

public partial class MyButton3D : Area3D
{
	[Export] public float RequiredWeight = 100.0f;
	public bool isActivated {get; private set;} = false;
	
	//get the visible 3D model of the button and its position
	private MeshInstance3D buttonMesh;
	private Vector3 buttonStartPos = new Vector3();
	
	//animate the button pressing
	private float targetY = 50.0f;
	private float currentYAnimation = 0.0f;
	[Export] private float animSpeed = 0.05f;
	[Export] private float pressDepth = 0.16f;
	
	private float currentWeight = 0.0f;
	
	public override void _Ready()
	{
		Connect("body_entered", new Callable(this, nameof(OnBodyEntered)));
		Connect("body_exited", new Callable(this, nameof(OnBodyExited)));
		buttonMesh = GetParent().GetNode<MeshInstance3D>("MeshInstance3D");
		buttonStartPos = buttonMesh.GlobalPosition; 
	}
	
	private void OnBodyEntered(Node3D body)
	{
		String ObjCollision = $"Collided with: {body.Name}";
		GD.Print(ObjCollision);
		// collide with weighted objects
		if (body is IWeighted weighted)
		{
			// Handle collision with a RigidBody3D
			currentWeight += weighted.Weight;
		}
	}
	
	private void OnBodyExited(Node3D body)
	{
		String ObjCollision = $"Body Exited: {body.Name}";
		GD.Print(ObjCollision);
		// You can check the type or group of the 'body' here
		if (body is IWeighted weighted)
		{
			// Handle collision with a RigidBody3D
			currentWeight -= weighted.Weight;
		}
	}
	
	public override void _Process(double delta)
	{
		//the button can be pressed down now!
		if(currentWeight >= RequiredWeight){
			isActivated = true;
		}else{
			isActivated = false;
		}
		
		//animate the button depressing
		if(isActivated){
			currentYAnimation = Mathf.Clamp(currentYAnimation + animSpeed, 0.0f, pressDepth);
		}else{
			currentYAnimation = Mathf.Clamp(currentYAnimation - animSpeed, 0.0f, pressDepth);
		}
		
		buttonMesh.GlobalPosition = new Vector3(buttonStartPos.X, buttonStartPos.Y - currentYAnimation, buttonStartPos.Z);
	}
	
	public override void _PhysicsProcess(double delta)
	{
		//physics logic stuffs
	}
}
