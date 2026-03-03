using Godot;

namespace Robobotomy.Scripts;

public partial class PhysicsPlayer : RigidBody3D
{
    [Export] public float MoveSpeed = 5.0f;
    [Export] public float JumpForce = 5.0f;
    [Export] public float FallMultiplier = 3.0f;
    [Export] public float JumpMultiplier = 1.7f;
    [Export] public float Deceleration = 20.0f;
    [Export] public float MaxFallSpeed = 7.5f;
    private float _baseGravity;
    private bool _isGrounded = false;
    // Adjust this threshold to handle slopes
    private const float GroundNormalThreshold = 0.9f;
    
    private PhysicsMaterial _playerMaterial;

    public override void _Ready()
    {
        SetAxisLock(PhysicsServer3D.BodyAxis.AngularX, true);
        SetAxisLock(PhysicsServer3D.BodyAxis.AngularZ, true);
        
        GravityScale = 0.0f; 
        _baseGravity = ProjectSettings.GetSetting("physics/3d/default_gravity").AsSingle();
        LinearDampMode = DampMode.Replace;
        LinearDamp = 0.0f; 
        
        // Cache the material from the PhysicsMaterialOverride slot
        if (PhysicsMaterialOverride != null) {
            _playerMaterial = PhysicsMaterialOverride;
        } else {
            GD.PrintErr("Please assign a PhysicsMaterial to the PhysicsMaterialOverride slot!");
        }
    }
    public override void _IntegrateForces(PhysicsDirectBodyState3D state)
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
            
            // Apply a force to match the desired speed instantly
            // This method works better than complex force calculations inside IntegrateForces
            state.LinearVelocity += velocityChange; 
        }
        else // No input, apply a specific horizontal deceleration force
        {
            // Simple deceleration by applying a force opposite the current velocity
            state.ApplyCentralForce(-currentHorizontalVelocity.Normalized() * Mass * Deceleration);
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
            ApplyCentralImpulse(Vector3.Up * JumpForce * Mass);
        }
        
        // --- FRICTION TOGGLE ---
        if (_playerMaterial != null)
        {
            // When grounded, use friction (e.g., 1.0) so you don't slide on slopes.
            // When in air, use 0.0 to prevent sticking to walls.
            _playerMaterial.Friction = _isGrounded ? 1.0f : 0.0f;
        }
        
        // --- GRAVITY LOGIC ---
        Vector3 gravityVector = Vector3.Down * _baseGravity * Mass;
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

