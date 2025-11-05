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

    private Dictionary<LimbTypes, PackedScene> enumToNode = new();
    private Dictionary<LimbTypes, Node3D> bodyObjects = new()
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
    public static LimbSelect instance;
    private Camera3D mainCamera;

    //Singleton to allow for PlayerLimbs to access this script
    public override void _EnterTree()
    {
        if(instance == null)
        {
            instance = this;
        }
        else
        {
            QueueFree();
        }
    }

    public override void _Ready()
    {


        enumToNode.Add(LimbTypes.Head, GD.Load<PackedScene>("res://Scenes/Characters/Head.tscn"));
        enumToNode.Add(LimbTypes.LeftArm, GD.Load<PackedScene>("res://Scenes/Characters/Arm.tscn"));
        enumToNode.Add(LimbTypes.RightArm, GD.Load<PackedScene>("res://Scenes/Characters/Arm.tscn"));
        enumToNode.Add(LimbTypes.LeftLeg, GD.Load<PackedScene>("res://Scenes/Characters/Leg.tscn"));
        enumToNode.Add(LimbTypes.RightLeg, GD.Load<PackedScene>("res://Scenes/Characters/Leg.tscn"));

        bodyObjects[LimbTypes.Torso] = GetNode<PlayerLimbs>("DetachablePlayer");

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
            if (bodyObjects[selectedLimb] != null && selectedLimb != LimbTypes.Torso)
            {
                recallLimb(bodyObjects[selectedLimb]);
            }
            else if (selectedLimb == LimbTypes.Torso)
            {
                for (int i = 0; i < 6; i++)
                {
                    if (i == 3) continue;
                    LimbTypes limbParse = (LimbTypes)i;
                    if (bodyObjects[limbParse] != null)
                    {
                        recallLimb(bodyObjects[limbParse]);
                    }
                }
            }
        }

        if (hasSwapped)
        {
            SwapCamera(selectedLimb);
        }

        if (Input.IsActionJustPressed("Player_Throw_Limb"))
        {
            if(bodyObjects[selectedLimb] == null && cameraLimb == LimbTypes.Torso)
            {
                PackedScene scene = enumToNode[selectedLimb];
                Node3D currentTarget = (Node3D)scene.Instantiate();
                ((PlayerLimbs)currentTarget).bodyParts[3] = false;
                AddChild(currentTarget);
                currentTarget.Position = bodyObjects[LimbTypes.Torso].Position;
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
                bodyObjects[selectedLimb] = currentTarget;
                ((PlayerLimbs)bodyObjects[LimbTypes.Torso]).bodyParts[(int)selectedLimb] = false;
                findLimb(selectedLimb).Visible = false;
                ThrowLimb(bodyObjects[selectedLimb]);
            }
        }
    }

    private void SwapCamera(LimbTypes targetLimb)
    {
        if (bodyObjects[targetLimb] == null) targetLimb = LimbTypes.Torso;
        for (int i = 0; i < 6; i++)
        {
            LimbTypes limbParse = (LimbTypes)i;
            if (bodyObjects[limbParse] == null) continue;
            if (limbParse != targetLimb)
            {
                ((PlayerLimbs)bodyObjects[limbParse]).isSelected = false;
                Node3D phantomCamera = bodyObjects[limbParse].GetNode<Node3D>("PhantomCamera3D");
                phantomCamera.Call("set_priority", 0);
            }
            else
            {
                cameraLimb = targetLimb;
                ((PlayerLimbs)bodyObjects[limbParse]).isSelected = true;
                Node3D phantomCamera = bodyObjects[limbParse].GetNode<Node3D>("PhantomCamera3D");
                phantomCamera.Call("set_priority", 1);
            }
        }
    }

    private void ThrowLimb(Node3D currentNode)
    {
        Vector3 mousePosition = mainCamera.ProjectPosition(GetViewport().GetMousePosition(), Math.Abs(mainCamera.Position.Z - bodyObjects[LimbTypes.Torso].Position.Z));
        Vector3 direction = bodyObjects[LimbTypes.Torso].Position.DirectionTo(new Vector3(mousePosition.X, mousePosition.Y, 0));
        ((PlayerLimbs)currentNode).Velocity = direction * throwSpeed;

    }

    private Node3D findLimb(LimbTypes limbToFind)
    {
        switch (limbToFind)
        {
            case LimbTypes.Head:
                return GetNode<Node3D>("DetachablePlayer/Head");
            case LimbTypes.LeftArm:
                return GetNode<Node3D>("DetachablePlayer/Left Arm");
            case LimbTypes.Torso:
                return GetNode<Node3D>("DetachablePlayer/Torso");
            case LimbTypes.RightArm:
                return GetNode<Node3D>("DetachablePlayer/Right Arm");
            case LimbTypes.LeftLeg:
                return GetNode<Node3D>("DetachablePlayer/Left Leg");
            case LimbTypes.RightLeg:
                return GetNode<Node3D>("DetachablePlayer/Right Leg");
            default:
                GD.Print("What");
                return null;
        }
    }

    private void recallLimb(Node3D currentNode)
    {
        ((PlayerLimbs)currentNode).isRecalling = true;
        ((PlayerLimbs)currentNode).targetObject = bodyObjects[LimbTypes.Torso];
        /*Vector3 direction = currentNode.Position.DirectionTo(bodyObjects[LimbTypes.Torso].Position);
        ((PlayerLimbs)currentNode).Velocity = direction * recallSpeed;*/
    }

    //Called by Torso
    public void limbIsRecalled(PlayerLimbs currentNode)
    {
        LimbTypes currentLimb = LimbTypes.Head;
        for(int i = 0; i < 6; i++)
        {
            if((bool)currentNode.bodyParts[i]){ currentLimb = (LimbTypes)i; }
        }
        bodyObjects[currentLimb].QueueFree();
        findLimb(currentLimb).Visible = true;
        bodyObjects[currentLimb] = null;
        ((PlayerLimbs)bodyObjects[LimbTypes.Torso]).bodyParts[(int)currentLimb] = true;
        currentLimb = LimbTypes.Torso;
        SwapCamera(currentLimb);
    }
}
