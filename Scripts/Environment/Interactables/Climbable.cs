using Godot;

public abstract partial class Climbable : Interactable
{
	// --- Exported variables ---
	[Export] public float ClimbSpeed { get; set; } = 0.2f;
	[Export] public float SlideSpeed { get; set; } = 1.0f;
	[Export] public float UpperClimbLimit { get; set; } = 0.5f;
	[Export] public float LowerClimbLimit { get; set; } = 0.0f;

	// --- Internal state ---
	public float GrabPosition { get; set; } = 0.0f;

	// --- Abstract methods ---
	public abstract override void InteractWith(Node3D interactor);

	public abstract Vector3 GetGrabPoint();
	public abstract void Climb(Vector3 dir, float speed);
	public abstract void Push(Vector3 dir, float force);
	public abstract Vector3 JumpOff();
}
