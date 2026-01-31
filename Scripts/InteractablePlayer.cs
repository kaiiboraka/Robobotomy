using Godot;
using Godot.Collections;
using System;

public partial class Player : CharacterBody3D, IWeighted
{
	[Export] public float Weight { get; set; } = 5.0f;
	
	public const float Speed = 5.0f;
	public const float JumpVelocity = 4.5f;
	
	private const float weightLimit = 3.25f;
	private Array<Node> interactables = new Array<Node>();
	private Node currInteraction;
	private bool climbing = false;
	private float carryWeight = 0.0f;

	public override void _PhysicsProcess(double delta)
	{

		Vector3 velocity = Velocity;
		
		// Get the input direction and handle the movement/deceleration.
		// As good practice, you should replace UI actions with custom gameplay actions.
		Vector2 inputDir = Input.GetVector("Player_Move_Left", "Player_Move_Right", "Player_Move_Up", "Player_Move_Down");
		Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
		
		if (climbing) 
		{
			GlobalPosition = currInteraction.Call("get_rope_point").As<Vector3>();
			
			if (direction != Vector3.Zero)
			{
				currInteraction.Call("push_rope", direction, Speed * (float)delta);
				Vector3 climbDirection = (Transform.Basis * new Vector3(0, inputDir.Y, 0)).Normalized();
				currInteraction.Call("climb_rope", climbDirection, Speed * (float)delta);
			}
			
			if (Input.IsActionJustPressed("Player_Jump"))
			{
				StopInteraction();
			}
		} 
		else 
		{
			float horizontalWeightFactor = Mathf.Max(0.0f, 1.0f - (carryWeight / weightLimit));
			float verticalWeightFactor = Mathf.Max(0.0f, 1.0f - (carryWeight * 1.5f / weightLimit));
			// Add the gravity.
			if (!IsOnFloor())
			{
				velocity += GetGravity() * (float)delta;
			}

			// Handle Jump.
			if (Input.IsActionJustPressed("Player_Jump") && IsOnFloor())
			{
				velocity.Y = JumpVelocity * verticalWeightFactor;
			}

			if (direction != Vector3.Zero)
			{
				velocity.X = direction.X * Speed * horizontalWeightFactor;
				// velocity.Z = direction.Z * Speed * horizontalWeightFactor;
			}
			else
			{
				velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed) * horizontalWeightFactor;
				// velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed) * horizontalWeightFactor;
			}

			Velocity = velocity;
			MoveAndSlide();
		}
		
		for (int i = 0; i < GetSlideCollisionCount(); i++)
		{
			KinematicCollision3D collision = GetSlideCollision(i);
			if (collision.GetCollider() is RigidBody3D body)
			{
	   			Vector3 pushDir = -collision.GetNormal();
				body.ApplyCentralForce(pushDir * (float)delta * 1200f);
			}
		}

	}
	
	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event.IsActionPressed("Player_Interact"))
		{
			if (currInteraction == null)
				Interact();
			else
				StopInteraction();
		}
	}
	
	public void AddInteractable(Node obj)
	{
		if (obj == null || !GodotObject.IsInstanceValid(obj))
			return;
		interactables.Add(obj);
	}

	public void RemoveInteractable(Node obj)
	{
		interactables.Remove(obj);
		if (currInteraction == obj)
			StopInteraction();
	}
	
	public void Interact()
	{
		int interactableCount = interactables.Count;
		if (interactableCount == 0)
			return;

		currInteraction = interactables[interactableCount - 1];
		if (currInteraction.IsInGroup("Climbable"))
		{
			climbing = true;
		}
		currInteraction.Call("interact_with", this);
	}

	public void StopInteraction()
	{
		if (climbing)
		{
			climbing = false;
			Velocity = currInteraction.Call("get_tangental_velocity").As<Vector3>();
		}
		currInteraction.Call("stop_interaction", this);
		currInteraction = null;
	}
	
	public void SetCarryWeight(float amount)
	{
		carryWeight = amount;
  }

	public void OnBodyEntered(Node3D body)
	{
		
	}
}
