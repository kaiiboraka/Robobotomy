using Godot;
using System;

public static class Movement
{
    public static float MoveSpeed = 5.0f;
    public static float JumpForce = 5.0f;
    public static float FallMultiplier = 3.0f;
    public static float JumpMultiplier = 1.7f;
    public static float Deceleration = 20.0f;
    public static float MaxFallSpeed = 7.5f;
    private static float _baseGravity;
    private static bool _isGrounded = false;
    // Adjust this threshold to handle slopes
    private const float GroundNormalThreshold = 0.9f;
    
    public static void MoveMe(RigidBody3D rb, bool isGrounded, int speed, int jumpHeight)
    {
        Vector2 inputDir = Input.GetVector("Player_Move_Left", "Player_Move_Right", "Player_Move_Up", "Player_Move_Down");
        Vector3 direction = (rb.Transform.Basis * new Vector3(inputDir.X, 0, 0)).Normalized();
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

    

    public static void _Ready(RigidBody3D rb)
    {
        rb.SetAxisLock(PhysicsServer3D.BodyAxis.AngularX, true);
        rb.SetAxisLock(PhysicsServer3D.BodyAxis.AngularZ, true);
        
        rb.GravityScale = 0.0f; 
        _baseGravity = ProjectSettings.GetSetting("physics/3d/default_gravity").AsSingle();
        rb.LinearDampMode = RigidBody3D.DampMode.Replace;
        rb.LinearDamp = 0.0f; 
    }
    
    
    public static void _IntegrateForces(PhysicsDirectBodyState3D state, RigidBody3D rb)
    {
        // Get input direction
        Vector3 inputDir = Vector3.Zero;
        if (Input.IsActionPressed("ui_left")) inputDir.X -= 1;
        if (Input.IsActionPressed("ui_right")) inputDir.X += 1;
        
        Vector3 currentHorizontalVelocity = new Vector3(state.LinearVelocity.X, 0, state.LinearVelocity.Z);

        if (inputDir.LengthSquared() > 0)
        {
            Vector3 targetVelocity = inputDir * MoveSpeed;
            Vector3 velocityChange = targetVelocity - currentHorizontalVelocity;
            
            // We apply a force to match the desired speed instantly
            // This method works better than complex force calculations inside IntegrateForces
            state.LinearVelocity += velocityChange; 
        }
        else // No input, apply a specific horizontal deceleration force
        {
            // Simple deceleration by applying a force opposite the current velocity
            state.ApplyCentralForce(-currentHorizontalVelocity.Normalized() * rb.Mass * Deceleration);
        }
        
        // Check if player is on ground
        bool foundGround = false;
        int contactCount = state.GetContactCount();

        for (int i = 0; i < contactCount; i++)
        {
            Vector3 normal = state.GetContactLocalNormal(i);
            // Check if the contact normal points mostly upwards (relative to the global UP vector)
            if (Vector3.Up.Dot(normal) > GroundNormalThreshold)
            {
                foundGround = true;
            }
        }
        _isGrounded = foundGround;
        
        // Handle Jump
        if (Input.IsActionJustPressed("ui_up") && _isGrounded)
        {
            rb.ApplyCentralImpulse(Vector3.Up * JumpForce * rb.Mass);
        }
        
        // --- GRAVITY LOGIC ---
        Vector3 gravityVector = Vector3.Down * _baseGravity * rb.Mass;
        // Always apply base gravity first
        state.ApplyCentralForce(gravityVector); 

        // Apply extra force only if falling and velocity is downward
        if (state.LinearVelocity.Y < 0)
        {
            state.ApplyCentralForce(gravityVector * (FallMultiplier - 1.0f));
        }
        // Apply extra force only if rising and jump button released
        else if (state.LinearVelocity.Y > 0 && !Input.IsActionPressed("ui_up"))
        {
            state.ApplyCentralForce(gravityVector * (JumpMultiplier - 1.0f));
        } 
        
        // --- CAP THE FALL SPEED ---
        // Clamp the Y velocity to ensure it never goes below -MaxFallSpeed
        state.LinearVelocity = new Vector3(
            state.LinearVelocity.X,
            Mathf.Max(state.LinearVelocity.Y, -MaxFallSpeed),
            state.LinearVelocity.Z
        );
    }
    
    

}
