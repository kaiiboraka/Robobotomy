using Godot;
using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;

public partial class Torso : RigidBody3D, ISelectable, IHub
{
    //ISelectable
    public bool amIsolated{ get; set; }
    public ActualPlayer.LimbTypes myType{get;set;}
    //IHub
    public Dictionary<ActualPlayer.LimbTypes, Socket> Sockets {get;set;}
    public List<ISelectable> myConnections { get; set; }
    public int numLegs { get; set; } = 0;
    public bool amSelected {get;set;}
    public int numArms { get; set; } = 0;

	//Movement
	[Export] private int speed = 3;
	private int jumpHeight = 0;
	private int strength = 0;
	private Node3D phantomCamera;

	//Collision
	private bool isGrounded;
	[Export]private int groundContacts;
	private Area3D jumpArea;
	private CollisionShape3D collider;

	//Ready
	public override void _Ready()
	{
		myType = ActualPlayer.LimbTypes.Torso;
		myConnections = new List<ISelectable>();
		amIsolated = true;
		phantomCamera = GetNode<Node3D>("PhantomCamera3D");
		jumpArea = GetNode<Area3D>("JumpArea");
		collider = GetNode<CollisionShape3D>("CollisionShape3D");
		jumpArea.BodyEntered += OnHitFloor;
		jumpArea.BodyExited += OnLeaveFloor;

		//Sockets
		Sockets = new Dictionary<ActualPlayer.LimbTypes, Socket>
		{
			{ ActualPlayer.LimbTypes.LeftArm, new Socket() //LeftArm
			{
				isUsed=false,
				position=new Vector3(0.64f, 0,0)
			} },
			{ ActualPlayer.LimbTypes.RightArm, new Socket() //RightArm
			{
				isUsed=false,
				position=new Vector3(-0.64f, 0,0)
			}
			},
			{ ActualPlayer.LimbTypes.LeftLeg, new Socket() //LeftLeg
			{
				isUsed = false,
				position=new Vector3(0.188f, -0.512f, 0)
			}
			},
			{ActualPlayer.LimbTypes.RightLeg, new Socket() //RightLeg
			{
				isUsed=false,
				position=new Vector3(-0.188f, -0.512f, 0)
			}
			},
			{ActualPlayer.LimbTypes.Head, new Socket() //Head
			{
				isUsed=false,
				position=new Vector3(0, 0.75f, 0)
			}
			}
		};

        Movement._Ready(this);

	}

	//ISelectable
	public ISelectable OnSelect()
	{
		if (amIsolated)
		{
			Freeze = false;
			phantomCamera.Call("set_priority", 1);
			return this;
		}
		else
		{
			GetParent<ISelectable>().OnSelect();
			return GetParent<ISelectable>();
		}
	}
	
	public void Deselect()
	{
		phantomCamera.Call("set_priority", 0);
	}

	public void OnConnect()
	{
		Freeze = true;
	}

	//IHub
	public void AddConnection(ISelectable addedItem)
	{
		bool canAdd = false;
		foreach (ActualPlayer.LimbTypes socket in Sockets.Keys)
		{
			if (addedItem.myType == socket) { canAdd = true; break; }
		}
		if (!canAdd) return;
		Socket gotSocket = Sockets[addedItem.myType];
		if (gotSocket.isUsed) return;
		myConnections.Add(addedItem);
		addedItem.amIsolated = false;
		addedItem.SetParent(this);
		addedItem.OnConnect(gotSocket.position, this);
		gotSocket.isUsed = true;
		gotSocket.connectedObject = addedItem;
		Sockets[addedItem.myType] = gotSocket;
	}

	public void RemoveConnection(ISelectable removedItem)
	{
		Socket gotSocket = Sockets[removedItem.myType];
		if (!gotSocket.isUsed) { GD.Print("I can't remove something I don't have"); return; }
		myConnections.Remove(removedItem);
		removedItem.OnDeconnect(this);
		removedItem.SetParent(GetParent());
		removedItem.amIsolated = true;
		gotSocket.isUsed = false;
		gotSocket.connectedObject = null;
		Sockets[removedItem.myType] = gotSocket;
	}
	
	public void RemoveConnection(ActualPlayer.LimbTypes removeType)
	{
		Socket gotSocket = Sockets[removeType];
		if (!gotSocket.isUsed) { GD.Print("I can't remove something I don't have"); return; }
		ISelectable removedItem = gotSocket.connectedObject;
		myConnections.Remove(removedItem);
		removedItem.OnDeconnect(this);
		removedItem.SetParent(GetParent());
		removedItem.amIsolated = true;
		gotSocket.isUsed = false;
		gotSocket.connectedObject = null;
		Sockets[removedItem.myType] = gotSocket;
	}

	public void ChangeHeight(bool legs)
	{
		if (legs)
		{
			if (numLegs > 1) return;
			Vector3 myPos = Position;
			myPos.Y += 1;
			Position = myPos;
			((CapsuleShape3D)collider.Shape).Height = 2;
			((CapsuleShape3D)jumpArea.GetChild<CollisionShape3D>(0).Shape).Height = 2;
		}
		else
		{
			if (numLegs > 0) return;
			((CapsuleShape3D)collider.Shape).Height = 1.466f;
			((CapsuleShape3D)jumpArea.GetChild<CollisionShape3D>(0).Shape).Height = 1.466f;
		}
	}

    //Movement
    public override void _IntegrateForces(PhysicsDirectBodyState3D state)
    {
        Movement._IntegrateForces(state, this);
    }
    public void MoveMe() //This is ISelectable but it's movement so I put it in movement
    {
        for (int i = 0; i < myConnections.Count; i++)
        {
            myConnections[i].ConnectedBehavior();
        }
        Movement.MoveMe(this, isGrounded, speed, 5);
    }

	//Doesn't do anything without legs
	public void OnHitFloor(Node3D body)
	{
		if (numLegs == 0) return;
		isGrounded = Movement.OnHitFloor(body, groundContacts);
	}

	public void OnLeaveFloor(Node3D body)
	{
		isGrounded = Movement.OnLeaveFloor(body, groundContacts);
	}

}
