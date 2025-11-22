using Godot;
using System;

public static class Movement
{
    public static void MoveMe(RigidBody3D rb, bool isGrounded, int speed, int jumpHeight)
    {
        Vector2 inputDir = Input.GetVector("Player_Move_Left", "Player_Move_Right", "Player_Move_Up", "Player_Move_Down");
        Vector3 direction = (rb.Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
        Vector3 desiredVelocity = direction * speed;
        Vector3 movement = desiredVelocity - rb.LinearVelocity;
        movement[1] = 0;
        rb.LinearVelocity += movement;
        if (Input.IsActionJustPressed("Player_Jump"))
        {
            if (isGrounded)
            {
                rb.ApplyCentralImpulse(Vector3.Up * jumpHeight);
            }
        }
    }

    public static bool OnHitFloor(Node3D body, int groundContacts)
    {
        groundContacts += 1;
        return (groundContacts > 0);
    }

    public static bool OnLeaveFloor(Node3D body, int groundContacts)
    {
        groundContacts -= 1;
        return groundContacts > 0;
    }

}
