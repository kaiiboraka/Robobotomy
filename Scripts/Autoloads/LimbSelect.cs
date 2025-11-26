using Godot;
using GodotPlugins.Game;
using System;
using System.Collections.Generic;

// using System.Collections.Generic;

namespace Robobotomy;

public partial class LimbSelect : Node
{
    //Enum and Dictionary Nonsense
    public enum LimbTypes { Head, LeftArm, RightArm, Torso, LeftLeg, RightLeg }

    private LimbTypes selectedLimb = LimbTypes.Torso;
    private LimbTypes cameraLimb = LimbTypes.Torso;

    private Dictionary<LimbTypes, PackedScene> limbScenes = new();
    private Dictionary<LimbTypes, Node3D> limbInstances = new()
    {
        {LimbTypes.Head,null },
        {LimbTypes.LeftArm, null},
        {LimbTypes.RightArm, null},
        {LimbTypes.Torso, null },
        {LimbTypes.LeftLeg, null},
        {LimbTypes.RightLeg, null}
    };

    //Exported Variables
    [Export] public float throwSpeed;
    [Export] public float recallSpeed;

    //Other vars
    public static LimbSelect Instance;
    private Camera3D mainCamera;

    //Singleton to allow for PlayerLimbs to access this script
    public override void _EnterTree()
    {
        if(Instance == null)
        {
            Instance = this;
        }
        else
        {
            QueueFree();
        }
    }

    public override void _Ready()
    {
        limbScenes.Add(LimbTypes.Head, GD.Load<PackedScene>("res://Scenes/Characters/Head.tscn"));
        limbScenes.Add(LimbTypes.LeftArm, GD.Load<PackedScene>("res://Scenes/Characters/Arm.tscn"));
        limbScenes.Add(LimbTypes.RightArm, GD.Load<PackedScene>("res://Scenes/Characters/Arm.tscn"));
        limbScenes.Add(LimbTypes.LeftLeg, GD.Load<PackedScene>("res://Scenes/Characters/Leg.tscn"));
        limbScenes.Add(LimbTypes.RightLeg, GD.Load<PackedScene>("res://Scenes/Characters/Leg.tscn"));

        limbInstances[LimbTypes.Torso] = GetNode<PlayerLimbs>("DetachablePlayer");

        mainCamera = GetViewport().GetCamera3D();
    }

    public override void _Process(double delta)
    {
        bool hasSwapped = false;
        if (Input.IsActionJustPressed("Number1")) { selectedLimb = LimbTypes.Head; hasSwapped = true; }
        if (Input.IsActionJustPressed("Number2")) { selectedLimb = LimbTypes.LeftArm; hasSwapped = true; }
        if (Input.IsActionJustPressed("Number3")) { selectedLimb = LimbTypes.Torso; hasSwapped = true; }
        if (Input.IsActionJustPressed("Number4")) { selectedLimb = LimbTypes.RightArm; hasSwapped = true; }
        if (Input.IsActionJustPressed("Number5")) { selectedLimb = LimbTypes.LeftLeg; hasSwapped = true; }
        if (Input.IsActionJustPressed("Number6")) { selectedLimb = LimbTypes.RightLeg; hasSwapped = true; }

        if (Input.IsActionJustPressed("Player_Recall"))
        {
            TryRecall();
        }

        if (hasSwapped)
        {
            SwapCamera(selectedLimb);
        }

        if (Input.IsActionJustPressed("Player_Throw_Limb"))
        {
            TryThrowLimb();
        }
    }

    private void TryRecall()
    {
        if (limbInstances[selectedLimb] != null && selectedLimb != LimbTypes.Torso)
        {
            RecallLimb(limbInstances[selectedLimb]);
        }
        else if (selectedLimb == LimbTypes.Torso)
        {
            for (int i = 0; i < 6; i++)
            {
                if (i == 3) continue;
                LimbTypes limbParse = (LimbTypes)i;
                if (limbInstances[limbParse] != null)
                {
                    RecallLimb(limbInstances[limbParse]);
                }
            }
        }
    }

    private void SwapCamera(LimbTypes targetLimb)
    {
        if (limbInstances[targetLimb] == null) targetLimb = LimbTypes.Torso;
        for (int i = 0; i < 6; i++)
        {
            LimbTypes limbParse = (LimbTypes)i;
            if (limbInstances[limbParse] == null) continue;
            if (limbParse != targetLimb)
            {
                ((PlayerLimbs)limbInstances[limbParse]).isSelected = false;
                Node3D phantomCamera = limbInstances[limbParse].GetNode<Node3D>("PhantomCamera3D");
                phantomCamera.Call("set_priority", 0);
            }
            else
            {
                cameraLimb = targetLimb;
                ((PlayerLimbs)limbInstances[limbParse]).isSelected = true;
                Node3D phantomCamera = limbInstances[limbParse].GetNode<Node3D>("PhantomCamera3D");
                phantomCamera.Call("set_priority", 1);
            }
        }
    }

    private void TryThrowLimb()
    {
        if(limbInstances[selectedLimb] == null && cameraLimb == LimbTypes.Torso)
        {
            PackedScene scene = limbScenes[selectedLimb];
            Node3D currentTarget = (Node3D)scene.Instantiate();
            ((PlayerLimbs)currentTarget).bodyParts[3] = false;
            AddChild(currentTarget);
            currentTarget.Position = limbInstances[LimbTypes.Torso].Position;
            for (int i = 0; i < 6; i++)
            {
                LimbTypes limbParse = (LimbTypes)i;
                if (limbParse == selectedLimb)
                {
                    ((PlayerLimbs)currentTarget).bodyParts[i] = true;
                }
                else
                {
                    ((PlayerLimbs)currentTarget).bodyParts[i] = false;
                }
            }
            limbInstances[selectedLimb] = currentTarget;
            ((PlayerLimbs)limbInstances[LimbTypes.Torso]).bodyParts[(int)selectedLimb] = false;
            FindLimb(selectedLimb).Visible = false;
            ThrowLimb(limbInstances[selectedLimb]);
        }
    }

    private void ThrowLimb(Node3D currentNode)
    {
        Vector3 mousePosition = mainCamera.ProjectPosition(GetViewport().GetMousePosition(), Math.Abs(mainCamera.Position.Z - limbInstances[LimbTypes.Torso].Position.Z));
        Vector3 direction = limbInstances[LimbTypes.Torso].Position.DirectionTo(new Vector3(mousePosition.X, mousePosition.Y, 0));
        ((PlayerLimbs)currentNode).Velocity = direction * throwSpeed;

    }

    private Node3D FindLimb(LimbTypes limbToFind)
    {
        return limbToFind switch
        {
            LimbTypes.Head => GetNode<Node3D>("DetachablePlayer/Head"),
            LimbTypes.LeftArm => GetNode<Node3D>("DetachablePlayer/Left Arm"),
            LimbTypes.Torso => GetNode<Node3D>("DetachablePlayer/Torso"),
            LimbTypes.RightArm => GetNode<Node3D>("DetachablePlayer/Right Arm"),
            LimbTypes.LeftLeg => GetNode<Node3D>("DetachablePlayer/Left Leg"),
            LimbTypes.RightLeg => GetNode<Node3D>("DetachablePlayer/Right Leg"),
            _ => null
        };
    }

    private void RecallLimb(Node3D currentNode)
    {
        ((PlayerLimbs)currentNode).isRecalling = true;
        ((PlayerLimbs)currentNode).targetObject = limbInstances[LimbTypes.Torso];
        /*Vector3 direction = currentNode.Position.DirectionTo(bodyObjects[LimbTypes.Torso].Position);
        ((PlayerLimbs)currentNode).Velocity = direction * recallSpeed;*/
    }

    //Called by Torso
    public void LimbIsRecalled(PlayerLimbs currentNode)
    {
        LimbTypes currentLimb = LimbTypes.Head;
        for(int i = 0; i < 6; i++)
        {
            if((bool)currentNode.bodyParts[i]){ currentLimb = (LimbTypes)i; }
        }
        limbInstances[currentLimb].QueueFree();
        FindLimb(currentLimb).Visible = true;
        limbInstances[currentLimb] = null;
        ((PlayerLimbs)limbInstances[LimbTypes.Torso]).bodyParts[(int)currentLimb] = true;
        currentLimb = LimbTypes.Torso;
        SwapCamera(currentLimb);
    }
}
