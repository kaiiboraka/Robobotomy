using System;
using System.Collections.Generic;
using Godot;

public interface ISelectable
{
    bool amIsolated { get; set; }
    bool amSelected { get; set; }
    ActualPlayer.LimbTypes myType {get;set;}
    ISelectable OnSelect();
    void OnConnect(Vector3 Position, IHub parent)
    {
        Deselect();
        ((Node3D)this).Position = Position;
    }
    void OnDeconnect(IHub parent){}
    void Deselect();
    void ConnectedBehavior(){}
    void MoveMe();
    void SetParent(Node parent)
    {
        Vector3 oldGlobalPos = ((Node3D)this).GlobalPosition;
        ((Node)this).GetParent().RemoveChild((Node)this);
        parent.AddChild((Node)this);
        ((Node3D)this).GlobalPosition = oldGlobalPos;
    }
}


public interface IPhysics
{
    void activatePhysics();
}

public interface IHub
{
    int numLegs { get; set; }
    int numArms{ get; set; }
    Dictionary<ActualPlayer.LimbTypes, Socket> Sockets{ get; set; }
    List<ISelectable> myConnections { get; set; }
    void AddConnection(ISelectable addedItem);
    void RemoveConnection(ISelectable removedItem);
    void ChangeHeight(bool legs);
}