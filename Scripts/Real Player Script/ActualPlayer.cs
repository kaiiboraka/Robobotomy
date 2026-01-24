using Godot;
using System;
using System.Collections.Generic;

// myGDScriptNode.Connect("my_signal_with_params", Callable.From<string, int>(MySignalWithParamsHandler));

public partial class ActualPlayer : Node
{
	private ISelectable selectedLimb;
	public enum LimbTypes { Head, LeftArm, Torso, RightArm, LeftLeg, RightLeg }
	public Dictionary<LimbTypes, ISelectable> starterLimbs = new Dictionary<LimbTypes, ISelectable>();
	public static ActualPlayer instance;
	public enum CharacterStates{}
	private Label3D selectedText;
	private Camera3D mainCamera;
	public override void _Ready()
	{
		// Get the eventbus singleton
		Node eventBus = (Node)GetNode("/root/EventBus");
		eventBus.Connect("limb_selected", Callable.From<int>(selectLimb));
		//Establish a singleton
		if (instance == null)
		{
			instance = this;
		}
		else
		{
			Free();
		}
		//Get the main Camera for throwing
		mainCamera = GetViewport().GetCamera3D();

		//Neatly organizes all limbs into a dict
		starterLimbs.Add(LimbTypes.Torso, GetNode<ISelectable>("Torso"));
		starterLimbs.Add(LimbTypes.LeftArm, GetNode<ISelectable>("LeftArm"));
		starterLimbs.Add(LimbTypes.RightArm, GetNode<ISelectable>("RightArm"));
		starterLimbs.Add(LimbTypes.LeftLeg, GetNode<ISelectable>("LeftLeg"));
		starterLimbs.Add(LimbTypes.RightLeg, GetNode<ISelectable>("RightLeg"));
		starterLimbs.Add(LimbTypes.Head, GetNode<ISelectable>("Head"));
		selectedText = GetNode<Label3D>("Torso/Label3D");

		//Set the torso as the current selected limb
		selectedLimb = starterLimbs[LimbTypes.Torso];
		selectedLimb.OnSelect();

		//Connect everything to the torso
		((IHub)selectedLimb).AddConnection(starterLimbs[LimbTypes.LeftArm]);
		((IHub)selectedLimb).AddConnection(starterLimbs[LimbTypes.RightArm]);
		((IHub)selectedLimb).AddConnection(starterLimbs[LimbTypes.LeftLeg]);
		((IHub)selectedLimb).AddConnection(starterLimbs[LimbTypes.RightLeg]);
		((IHub)selectedLimb).AddConnection(starterLimbs[LimbTypes.Head]);
	}
	private LimbTypes throwingLimb;

	public override void _PhysicsProcess(double delta)
	{
		selectedLimb.MoveMe();
		if (Input.IsActionJustPressed("Number1")) { //Head
			selectLimb(0);
			}
		if (Input.IsActionJustPressed("Number2")) { //LeftArm
			selectLimb(1);
			}
		if (Input.IsActionJustPressed("Number3")) { //Torso
			selectLimb(2);
			}
		if (Input.IsActionJustPressed("Number4")) { //RightArm
			selectLimb(3);
			}
		if (Input.IsActionJustPressed("Number5")) { //LeftLeg
			selectLimb(4);
			}
		if (Input.IsActionJustPressed("Number6")) { //RightLeg
			selectLimb(5);
			}
		selectedText.Text = throwingLimb.ToString();

		if (Input.IsActionJustPressed("Player_Throw_Limb"))
		{
			if(selectedLimb == starterLimbs[LimbTypes.Torso])
			{
				initiateThrow(starterLimbs[throwingLimb], (IHub)starterLimbs[LimbTypes.Torso]);
				throwingLimb = LimbTypes.Torso;
			}
			
		}

		if (Input.IsActionJustPressed("Player_Recall"))
		{
			if(selectedLimb == starterLimbs[LimbTypes.Torso])
			{
				foreach(ISelectable limb in starterLimbs.Values)
				{
					if (limb.amIsolated)
					{
						((IHub)starterLimbs[LimbTypes.Torso]).AddConnection(limb);
					}
				}
			}
			else
			{
				((IHub)starterLimbs[LimbTypes.Torso]).AddConnection(selectedLimb);
				selectedLimb = starterLimbs[LimbTypes.Torso];
				throwingLimb = LimbTypes.Torso;
				selectedLimb.OnSelect();
			}
		}
	}


	public void selectLimb(int limb)
	{
		/* 
		Player Limb enum order is:
		Head, Left Arm, Torso, Right Arm, Left Leg, Right Leg
		*/ 
		throwingLimb = (LimbTypes)limb;
		if (starterLimbs[throwingLimb].amIsolated)
		{
			selectedLimb.Deselect();
		}
		selectedLimb = starterLimbs[throwingLimb].OnSelect();
	}

	private void initiateThrow(ISelectable thrownLimb, IHub throwingLimb)
	{
		if(((Node3D)thrownLimb).GetParent().GetType() != typeof(Torso)) return;
		if(throwingLimb.numArms == 0) return;
		throwingLimb.RemoveConnection(thrownLimb);
		ThrowLimb((Node3D)thrownLimb);
	}

	private void ThrowLimb(Node3D currentNode)
	{
		Vector3 mousePosition = mainCamera.ProjectPosition(GetViewport().GetMousePosition(),
			Math.Abs(mainCamera.Position.Z - ((Node3D)starterLimbs[LimbTypes.Torso]).Position.Z));
		Vector3 direction =
			((Node3D)starterLimbs[LimbTypes.Torso]).Position.DirectionTo(new Vector3(mousePosition.X, mousePosition.Y,
				0));
		((RigidBody3D)currentNode).ApplyCentralImpulse(direction * 5);
	}
}
