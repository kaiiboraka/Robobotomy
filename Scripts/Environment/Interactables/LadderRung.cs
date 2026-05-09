using Godot;

[Tool]
public partial class LadderRung : Node3D
{
	private MeshInstance3D meshInstance;

	public override void _Ready()
	{
		meshInstance = GetNode<MeshInstance3D>("Mesh");
	}

	/// <summary>
	/// Updates the geometry of the rung by modifying the mesh.
	/// </summary>
	public void UpdateGeometry(float length, float width)
	{
		if (meshInstance?.Mesh is CylinderMesh cylinder)
		{
			// Modify the mesh *instance*
			cylinder = (CylinderMesh)cylinder.Duplicate();
			cylinder.Height = length;
			cylinder.BottomRadius = width;
			cylinder.TopRadius = width;

			meshInstance.Mesh = cylinder;
		}
	}
}
