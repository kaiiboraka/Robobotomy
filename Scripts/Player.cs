using Godot;
using Godot.Collections;
using System;

public partial class Player : CharacterBody3D, IWeighted
{
	[Export] public float Weight { get; set; } = 5.0f;
	
	public const float Speed = 5.0f;
	public const float JumpVelocity = 4.5f;
	
	private const float weightLimit = 3.25f;
	private Array<Interactable> interactables = new Array<Interactable>();
	private Interactable currInteraction;
	private bool climbing = false;
	private float carryWeight = 0.0f;
	private bool resetInteractable = false;

	public override void _PhysicsProcess(double delta)
	{

		Vector3 velocity = Velocity;
		
		// Get the input direction and handle the movement/deceleration.
		// As good practice, you should replace UI actions with custom gameplay actions.
		Vector2 inputDir = Input.GetVector("Player_Move_Left", "Player_Move_Right", "Player_Move_Up", "Player_Move_Down");
		Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
		
		if (climbing) 
		{
			Climbable climbable = currInteraction as Climbable;
			Vector3 target = climbable.GetGrabPoint();
			Vector3 newPos = GlobalPosition.Lerp(target, (float)delta * 10.0f);
			Vector3 motion = newPos - GlobalPosition;
			MoveAndCollide(motion);
			
			if (direction.X != 0)
			{
				climbable.Push(direction, Speed * (float)delta);
			} 
			else if (direction.Z != 0) 
			{
				Vector3 climbDirection = (Transform.Basis * new Vector3(0, inputDir.Y, 0)).Normalized();
				climbable.Climb(climbDirection, Speed * (float)delta);
			}
			
			if (Input.IsActionJustPressed("Player_Jump"))
			{
				StopInteraction();
				Velocity += new Vector3(0, JumpVelocity, 0);
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
				velocity.Z = direction.Z * Speed * horizontalWeightFactor;
			}
			else
			{
				velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed) * horizontalWeightFactor;
				velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed) * horizontalWeightFactor;
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
		if (obj is Interactable interactable && GodotObject.IsInstanceValid(interactable))
			interactables.Add(interactable);
	}

	public void RemoveInteractable(Node obj)
	{
		if (obj is Interactable interactable)
		{
			if (currInteraction != interactable)
				interactables.Remove(interactable);
			else
				resetInteractable = true;
		}
	}
	
	public void Interact()
	{
		int interactableCount = interactables.Count;
		if (interactableCount == 0)
			return;

		Interactable closestInteractable = interactables[0];
		for (int i = 1; i < interactableCount; i++)
		{
			float distanceTo = this.GlobalPosition.DistanceTo(interactables[i].GlobalPosition);
			if (distanceTo < this.GlobalPosition.DistanceTo(closestInteractable.GlobalPosition))
			{
				closestInteractable = interactables[i];
			}
		}
		currInteraction = closestInteractable;
		if (currInteraction.IsInGroup("Climbable"))
		{
			climbing = true;
		}
		currInteraction.InteractWith(this);
	}

	public void StopInteraction()
	{
		if (climbing)
		{
			climbing = false;
			if (currInteraction is Climbable climbable)
			{
				Velocity = climbable.JumpOff();
			}
		}
		if (resetInteractable)
			interactables.Remove(currInteraction);
		resetInteractable = false;
		currInteraction.StopInteraction(this);
		currInteraction = null;
		
		
	}
	
	public void SetCarryWeight(float amount)
	{
		carryWeight = amount;
  }
}
