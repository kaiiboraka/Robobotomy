using Godot;
using PhantomCamera;
using System;

public partial class Player : CharacterBody3D
{
	public const float Speed = 5.0f;
	public const float JumpVelocity = 4.5f;
	[Export]
	public bool isSelected = true;
    /*
	0:false, #Head
	1:false, #LeftArm
	2:false, #RightArm
	3:true, #Torso
	4:false, #LeftLeg
	5:false, #RightLeg

	*/
	public Godot.Collections.Dictionary bodyParts = new Godot.Collections.Dictionary()
	{
		{0, true}, //Head
		{1, true}, //LeftArm
		{2, true}, //RightArm
		{3, true }, //Torso
		{4, true}, //LeftLeg
		{5, true } //RightLeg
	};

	public override void _Ready()
	{
        
    }

	public override void _PhysicsProcess(double delta)
	{

		Vector3 velocity = Velocity;

		// Add the gravity.
		if (!IsOnFloor())
		{
			velocity += GetGravity() * (float)delta;
		}
		else
		{
			if (!isSelected) //Stop moving if on floor
			{
				velocity = Vector3.Zero;
			}

		}

		if (isSelected) //Am I selected?
		{

			if ((bool)bodyParts[4] == true || (bool)bodyParts[5] == true)
			{
				// Handle Jump.
				if (Input.IsActionJustPressed("Player_Jump") && IsOnFloor())
				{
					velocity.Y = JumpVelocity;
				}
			}

			// Get the input direction and handle the movement/deceleration.
			// As good practice, you should replace UI actions with custom gameplay actions.


			Vector2 inputDir = Input.GetVector("Player_Move_Left", "Player_Move_Right", "Player_Move_Up", "Player_Move_Down");
			Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
			if (direction != Vector3.Zero)
			{
				velocity.X = direction.X * Speed;
				velocity.Z = direction.Z * Speed;
			}
			else
			{
				velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed);
				velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed);
			}
		}
		//This runs regardless of selected or not
		Velocity = velocity;
		MoveAndSlide();
	}
}
