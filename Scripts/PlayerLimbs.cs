using Godot;
using Godot.Collections;
using PhantomCamera;
using Robobotomy;
using System;

public partial class PlayerLimbs : CharacterBody3D
{
	public const float Speed = 5.0f;
	public const float JumpVelocity = 4.5f;

	[Export] public bool isSelected = true;

	public bool isRecalling = false;

	public Dictionary bodyParts = new()
	{
		{ 0, true }, //Head
		{ 1, true }, //LeftArm
		{ 2, true }, //RightArm
		{ 3, true }, //Torso
		{ 4, true }, //LeftLeg
		{ 5, true } //RightLeg
	};

	private Area3D torsoArea;

	public Node3D targetObject;

	public override void _Ready()
	{
		if ((bool)bodyParts[3])
		{
			Area3D area3D = GetNode<Area3D>("Area3D");
			area3D.BodyEntered += OnBodyEntered;
		}
	}

	public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;
		if (isRecalling)
		{
			Vector3 direction = Position.DirectionTo(targetObject.Position);
			velocity = direction * 5;
		}

		// Add the gravity.
		if (!IsOnFloor())
		{
			velocity += GetGravity() * (float)delta;
		}
		else if (!isRecalling)
		{ //Stop moving if on floor
			if (!isSelected)
			{
				velocity = Vector3.Zero;
			}
			else
			{
				if ((bool)bodyParts[4] || (bool)bodyParts[5])
				{
					// Handle Jump.
					if (Input.IsActionJustPressed("Player_Jump") && IsOnFloor())
					{
						velocity.Y = JumpVelocity;
					}
				}

				// Get the input direction and handle the movement/deceleration.
				// As good practice, you should replace UI actions with custom gameplay actions.

				Vector2 inputDir = Input.GetVector("Player_Move_Left", "Player_Move_Right", "Player_Move_Up",
					"Player_Move_Down");
				Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
				if (direction != Vector3.Zero)
				{
					velocity.X = direction.X * Speed;
					// velocity.Z = direction.Z * Speed;
				}
				else
				{
					velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed);
					// velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed);
				}
			}
		}

		//This runs regardless of selected or not
		Velocity = velocity;
		MoveAndSlide();
	}

	public void OnBodyEntered(Node3D body)
	{
		PlayerLimbs limb = (PlayerLimbs)body;
		if (limb.isRecalling == false) return;
		for (int i = 0; i < 6; i++)
		{
			if ((bool)limb.bodyParts[i])
			{
				LimbSelect.Instance.LimbIsRecalled(limb);
				break;
			}
		}
	}
}