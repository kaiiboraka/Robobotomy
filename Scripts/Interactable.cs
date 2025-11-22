using Godot;

public abstract partial class Interactable : Node3D
{
	public abstract void InteractWith(Node3D interactor);
	public abstract void StopInteraction(Node3D interactor);

	private void OnInteractionAreaEntered(Area3D area)
	{
		if (area is InteractionArea)
		{
			Node3D player = area.GetParent<Node3D>();
			player.Call("AddInteractable", this);
		}
	}

	private void OnInteractionAreaExited(Area3D area)
	{
		if (area is InteractionArea)
		{
			Node3D player = area.GetParent<Node3D>();
			player.Call("RemoveInteractable", this);
		}
	}
}
