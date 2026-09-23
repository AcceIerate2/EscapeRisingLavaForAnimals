-- Roblox Services
local PhysicsService = game:GetService("PhysicsService")

-->
PhysicsService:RegisterCollisionGroup("PlayerCollisions")
PhysicsService:RegisterCollisionGroup("RagdollCollisions")

PhysicsService:CollisionGroupSetCollidable("PlayerCollisions", "PlayerCollisions", false)
PhysicsService:CollisionGroupSetCollidable("PlayerCollisions", "RagdollCollisions", false)

PhysicsService:CollisionGroupSetCollidable("RagdollCollisions", "RagdollCollisions", true)
PhysicsService:CollisionGroupSetCollidable("RagdollCollisions", "PlayerCollisions", false)
