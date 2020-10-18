
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

local effectfiles = file.Find( "entities/modulus_hoverboard/effects/*.lua", "LUA" )
for _, filename in pairs( effectfiles ) do AddCSLuaFile( "effects/" .. filename ) end

include( "shared.lua" )

AccessorFunc( ENT, "pitchspeed", "PitchSpeed", FORCE_NUMBER )
AccessorFunc( ENT, "yawspeed", "YawSpeed", FORCE_NUMBER )
AccessorFunc( ENT, "turnspeed", "TurnSpeed", FORCE_NUMBER )
AccessorFunc( ENT, "rollspeed", "RollSpeed", FORCE_NUMBER )
AccessorFunc( ENT, "jumppower", "JumpPower", FORCE_NUMBER )
AccessorFunc( ENT, "speed", "Speed", FORCE_NUMBER )
AccessorFunc( ENT, "boosterspeed", "BoostMultiplier", FORCE_NUMBER )
AccessorFunc( ENT, "dampingfactor", "DampingFactor", FORCE_NUMBER )
AccessorFunc( ENT, "spring", "Spring", FORCE_NUMBER )

function ENT:Precache()

	self.MountSoundFile = "buttons/button9.wav"
	self.UnMountSoundFile = "buttons/button19.wav"
	self.JumpSoundFile = "weapons/airboat/airboat_gun_energy1.wav"

	util.PrecacheSound( self.MountSoundFile )
	util.PrecacheSound( self.UnMountSoundFile )
	util.PrecacheSound( self.JumpSoundFile )

end

function ENT:UpdateTransmitState()

	return TRANSMIT_ALWAYS

end

function ENT:Initialize()

	self:Precache()

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetUseType( ONOFF_USE )

	self.WaterContacts = 0
	self.Contacts = 0
	self.MouseControl = 1
	self.CanPitch = false
	self:SetBoost( 100 )
	self.NextBoostThink = 0
	self:SetDampingFactor( 2 )
	self:SetSpeed( 20 )
	self:SetYawSpeed( 25 )
	self:SetTurnSpeed( 25 )
	self:SetPitchSpeed( 25 )
	self:SetRollSpeed( 20 )
	self:SetJumpPower( 250 )
	self:SetBoostMultiplier( 1.5 )
	self:SetSpring( 0.21 )
	self:SetHoverHeight( 72 )
	self:SetViewDistance( 128 )
	self:SetBoosting( false )
	self.PlayerMountedTime = 0

	self.PhysgunDisabled = false

	self:CreateAvatar()

	self.Hull = NULL

	local boardphys = self:GetPhysicsObject()
	if ( IsValid( boardphys ) ) then boardphys:SetMass( 750 ) end

	self:StartMotionController()

end

function ENT:CreateAvatar()

	self.Avatar = ents.Create( "modulus_hoverboard_avatar" )
	self.Avatar:SetParent( self )
	self.Avatar:Spawn()
	self.Avatar:SetBoard( self )
	self:SetNWEntity( "Avatar", self.Avatar )
	self:SetAvatarPosition( Vector( 0, 0, 3 ) )

end

function ENT:SetAvatarPosition( pos )

	self.Avatar:SetLocalPos( pos )
	self.Avatar:SetLocalAngles( Angle( 0, 160 + self:GetBoardRotation(), 0 ) )

end

function ENT:OnRemove()

	self:SetDriver( NULL )
	self:StopMotionController()

end

function ENT:SetControls( num )

	self.MouseControl = num

end

function ENT:SetDriver( pl )

	if ( !IsValid( self.Avatar ) ) then self:CreateAvatar() end
	self.Avatar:SetPlayer( pl )

	local driver = self:GetDriver()

	if ( IsValid( driver ) ) then

		if ( !IsValid( pl ) or GetConVarNumber( "sv_hoverboard_cansteal" ) == 1 ) then -- check if we should boot the driver

			driver:SetNWEntity( "ScriptedVehicle", NULL ) -- clear it's scripted vehicle

			self:UnMount( driver ) -- unmount

			driver:SetMoveType( driver.OldMoveType ) -- restore movetype
			driver:DrawWorldModel( true )
			driver:DrawViewModel( true )
			driver:SetNoDraw( false )

			self.PhysgunDisabled = false -- enable physgun again

			self:SetGrinding( false ) -- grinding off
			self:SetBoosting( false ) -- boost off

			if ( self.OldWeapon && driver:HasWeapon( self.OldWeapon ) ) then
				driver:SelectWeapon( self.OldWeapon )
			end
		else

			return

		end

	end

	self.PlayerMountedTime = 0
	self.OldWeapon = nil

	if ( IsValid( pl ) ) then

		-- can we get on it?
		if ( GetConVarNumber( "sv_hoverboard_canshare" ) < 1 && pl:UniqueID() != self.Creator ) then
			return
		end

		self.PlayerMountedTime = CurTime()

		-- create a hull if it doesn't exist
		if ( !IsValid( self.Hull ) ) then

			local boardphys = self:GetPhysicsObject()
			if ( IsValid( boardphys ) ) then

				self.Hull = ents.Create( "modulus_hoverboard_hull" )
				self.Hull:SetAngles( boardphys:GetAngles() )

				local pos = boardphys:GetPos()
				--if ( self:GetModel() == "models/squint_hoverboard/hotrod.mdl" ) then pos = pos + self:GetRight() * 16 end
				self.Hull:SetPos( pos )
				self.Hull:Spawn()
				self.Hull:SetPlayer( pl )
				self.Hull:SetOwner( self )

				constraint.Weld( self.Hull, self, 0, 0, 0, true, true )

			end

		else

			self.Hull:SetPlayer( pl ) -- simply update the driver

		end

		local weapon = pl:GetActiveWeapon()
		if ( IsValid( weapon ) ) then self.OldWeapon = weapon:GetClass() end
		--pl:SelectWeapon( "weapon_crowbar" ) -- Handled in think

		 -- don't allow us to mount if we already have a scripted vehicle
		if ( IsValid( pl:GetNWEntity( "ScriptedVehicle" ) ) ) then return end

		-- set scripted vehicle
		pl:SetNWEntity( "ScriptedVehicle", self )

		-- store our old movetype and prevent us from moving
		pl.OldMoveType = pl:GetMoveType()
		pl:SetMoveType( MOVETYPE_NOCLIP )

		self:Mount( pl )

		-- set board velocity (allows for a running start)
		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then

			local angles = self:GetAngles()
			angles:RotateAroundAxis( angles:Up(), self:GetBoardRotation() + 180 )
			local forward = angles:Forward()
			local velocity = forward:Dot( pl:GetVelocity() ) * forward

			phys:SetVelocity( velocity )

		end

		self.PhysgunDisabled = true

	else

		SafeRemoveEntity( self.Hull ) -- A player is getting off, destroy the hull

	end

	-- set new driver
	self:SetNWEntity( "Driver", pl )
	self:SetOwner( pl )

end

function ENT:HurtDriver( damage )

	local driver = self:GetDriver() -- get driver

	if ( !IsValid( driver ) or self.PlayerMountedTime == 0 or CurTime() - self.PlayerMountedTime < 1 ) then -- Validate
		return
	end

	driver:TakeDamage( damage, self ) -- inflict damage to our player

end

function ENT:SetBoost( int )

	self:SetNWInt( "Boost", int ) -- set flag

end

function ENT:SetBoosting( bool )

	self:SetNWBool( "Boosting", bool )

end

function ENT:IsUpright( physobj )

	local phys = self:GetPhysicsObject()
	if ( !IsValid( phys ) ) then return end

	local up = phys:GetAngles():Up()

	return ( up.z >= 0.33 )

end

function ENT:OnTakeDamage( dmginfo )

	self:TakePhysicsDamage( dmginfo )

end

local function SetPlayerAnimation( pl, anim )

	-- get the scripted vehicle
	local board = pl:GetNWEntity( "ScriptedVehicle" )

	-- make sure they are using the hoverboard
	if ( !IsValid( board ) or board:GetClass() != "modulus_hoverboard" ) then return end

	-- select animation
	local seq = "idle_slam"

	if ( board:IsGrinding() ) then

		seq = "cidle_melee"

	elseif ( pl.IsTurning ) then

		seq = "idle_grenade"

	end

	-- get the pose sequence
	seq = pl:LookupSequence( seq )

	-- run the animation
	pl:SetPlaybackRate( 1.0 )
	pl:ResetSequence( seq )
	pl:SetCycle( 0 )

	-- animate the avatar
	board.Avatar:SetPlaybackRate( 1.0 )
	board.Avatar:ResetSequence( seq )
	board.Avatar:SetCycle( 0 )

	-- override
	return true

end

hook.Add( "SetPlayerAnimation", "Hoverboard_SetPlayerAnimation", SetPlayerAnimation )

function ENT:Think()

	-- stay wake
	local phys = self:GetPhysicsObject()
	if ( IsValid( phys ) ) then phys:Wake() end

	local driver = self:GetDriver()
	if ( IsValid( driver ) ) then

		driver:DrawViewModel( false )
		driver:DrawWorldModel( false )
		driver:SetNoDraw( true )

		-- Make sure their active weapon is NULL
		-- So there's no weird things like toolgun ghost or something
		driver:SetActiveWeapon( NULL )

		-- make sure driver is still around
		if ( self:WaterLevel() > 0 or !driver:Alive() or !driver:IsConnected() ) then

			-- give 'em the boot
			self:SetDriver( NULL )

		-- make sure board is upright
		/*elseif ( self:GetUp().z < -0.85 ) then
			-- check if board is on ground
			if ( self.Contacts > 0 or self:OnGround() ) then
				-- give 'em the boot
				--self:SetDriver( NULL )
			end*/

		else

			-- get weapon
			local weap = driver:GetActiveWeapon()

			-- validate
			if ( IsValid( weap ) ) then

				-- disable attack
				weap:SetNextPrimaryFire( CurTime() + 1 )
				weap:SetNextSecondaryFire( CurTime() + 1 )

			end

		end

		-- maintain the animation
		if ( driver:Alive() && driver:IsConnected() ) then

			-- change the animation
			SetPlayerAnimation( driver )

		end

	elseif ( self.DriverWeapon != nil ) then

		-- no driver, no weapon
		self.DriverWeapon = nil

	end

	-- boost thinking
	if ( CurTime() >= self.NextBoostThink ) then

		-- set next think
		self.NextBoostThink = CurTime() + 0.1

		-- boosting
		if ( self:IsBoosting() ) then

			-- consume boost
			self:SetBoost( math.Clamp( self:Boost() - 1, 0, 100 ) )

			-- boost done
			if ( self:Boost() <= 0 ) then self:SetBoosting( false ) end

		else

			-- recharge boost
			self:SetBoost( math.Clamp( self:Boost() + 1, 0, 100 ) )

		end

	end

	self:NextThink( CurTime() )
	return true

end

function ENT:ApplyForwardForce( phys, force, mass )

	-- get the proper force to apply
	local ang = phys:GetAngles()
	ang:RotateAroundAxis( phys:GetAngles():Up(), self:GetBoardRotation() )
	ang = ang:Forward()

	-- calculate
	return phys:CalculateForceOffset(
		ang * force * mass,
		phys:GetPos() + phys:GetAngles():Up() * 0 -- it was up * 8 before
	)

end

function ENT:ApplySideForce( phys, force, mass )

	-- get the proper force to apply
	local ang = phys:GetAngles()
	ang:RotateAroundAxis( phys:GetAngles():Up(), self:GetBoardRotation() )
	ang = ang:Right()

	-- calculate
	return phys:CalculateForceOffset(
		ang * force * mass,
		phys:GetPos() + phys:GetAngles():Up() * 0 -- it was up * 8 before
	)

end

function ENT:ApplyRotateForce( phys, force, mass )

	-- two forces each at opposite ends of the board
	local _, force1 = phys:CalculateForceOffset(
		phys:GetAngles():Right() * force * mass,
		phys:GetPos() + phys:GetAngles():Forward() * -24 + phys:GetAngles():Up() * 1.36
	)
	local _, force2 = phys:CalculateForceOffset(
		phys:GetAngles():Right() * -force * mass,
		phys:GetPos() + phys:GetAngles():Forward() * 24 + phys:GetAngles():Up() * 1.36
	)

	return force1 + force2

end

function ENT:ApplyPitchForce( phys, force, mass )

	-- get the proper force to apply
	local ang = phys:GetAngles()
	ang:RotateAroundAxis( phys:GetAngles():Up(), self:GetBoardRotation() )
	ang = ang:Forward()

	-- two forces each at opposite ends of the board
	local _, force1 = phys:CalculateForceOffset(
		phys:GetAngles():Up() * force * mass,
		phys:GetPos() + ang * -24 + phys:GetAngles():Up() * 1.36
	)
	local _, force2 = phys:CalculateForceOffset(
		phys:GetAngles():Up() * -force * mass,
		phys:GetPos() + ang * 24 + phys:GetAngles():Up() * 1.36
	)

	return force1 + force2

end

function ENT:ApplyRollForce( phys, force, mass )

	-- get the proper force to apply
	local ang = phys:GetAngles()
	ang:RotateAroundAxis( phys:GetAngles():Up(), self:GetBoardRotation() )

	-- two forces each at opposite ends of the board
	local _, force1 = phys:CalculateForceOffset(
		ang:Up() * force * mass,
		phys:GetPos() + ang:Right() * -24
	)
	local _, force2 = phys:CalculateForceOffset(
		ang:Up() * -force * mass,
		phys:GetPos() + ang:Right() * 24
	)

	return force1 + force2

end

function ENT:SetGrinding( bool )

	-- physics object
	local phys = self:GetPhysicsObject()

	-- validate
	if ( IsValid( phys ) ) then

		if ( bool ) then

			-- sliding
			phys:SetMaterial( "ice" )

		else

			-- friction
			phys:SetMaterial( "metal" )

		end

	end

	-- update
	self:SetNWBool( "Grinding", bool )

end

function ENT:PhysicsCollide( data, physobj )

	-- get speed
	local velocity = self:GetVelocity()
	local speed = velocity:Length()

	-- minimum speed
	if ( speed < 150 ) then return end

	-- check entity
	if ( !data.HitEntity or data.HitEntity == NULL or self:WaterLevel() > 0 ) then return end

	-- make sure its world
	if ( data.HitEntity == game.GetWorld() or data.HitEntity:GetSolid() != SOLID_NONE ) then

		-- create effect
		local effectdata = EffectData()
		effectdata:SetOrigin( data.HitPos )
		effectdata:SetNormal( data.HitNormal )
		effectdata:SetMagnitude( 1.5 )
		effectdata:SetScale( 0.1 )
		effectdata:SetRadius( 12 )

		-- dispatch
		util.Effect( "sparks", effectdata, true, true )

		-- grinding sound
		self:SetNWFloat( "GrindSoundTime", CurTime() + 0.2 )

	end

end

function ENT:PhysicsSimulate( phys, deltatime )

	self.Contacts = 0
	self.WaterContacts = 0

	-- we spaz out if we hover when we're physgunned.
	if ( self:IsPlayerHolding() or self:WaterLevel() > 0 ) then

		-- go ahead and update next use
		self.NextUse = CurTime() + 1

		return SIM_NOTHING

	end

	local driver = self:GetDriver()
	local thrusters = #self.ThrusterPoints -- 5 is the magic number (#self.ThrusterPoints)
	local thruster_mass = phys:GetMass() / thrusters -- spread the mass evenly over all thrusters
	local hoverheight = math.Clamp( tonumber( self:GetHoverHeight() ), 36, 100 )

	-- force accumulators
	local angular = Vector( 0, 0, 0 )
	local linear = Vector( 0, 0, 0 )

	-- hover spring power
	local spring_power = self:GetSpring()

	-- damping
	local angle_velocity = phys:GetAngleVelocity()
	local velocity = phys:GetVelocity()
	local hover_damping = Vector( 0, 0, ( velocity.z * -4.8 ) / thrusters ) * self:GetDampingFactor()
	local angular_damping = angle_velocity * ( -6.4 / thrusters ) * self:GetDampingFactor()
	local friction = velocity * ( -3.6 / thrusters )

	-- friction shouldn't affect gravity
	friction.z = 0

	-- update board velocity
	self:SetBoardVelocity( velocity:Length() )

	-- for each hover point
	for i = 1, thrusters do

		local point = self:GetThruster( i )
		local tracelen = hoverheight - ( self.ThrusterPoints[ i ].Diff or 0 )

		-- trace
		local tr = util.TraceLine( {
			start = point,
			endpos = point - Vector( 0, 0, tracelen ),
			filter = { self, driver, self.Hull },
			mask = bit.bor( MASK_SOLID , MASK_WATER ),

		} )

		-- did we hit water?
		if ( tr.MatType == MAT_SLOSH ) then

			self.WaterContacts = self.WaterContacts + 1

		end

		-- should we apply forces to this thruster?
		if ( tr.Fraction < 1 && tr.Fraction > 0 ) then

			-- increment contacts
			self.Contacts = self.Contacts + 1

			-- calculate force and compression
			local compression = tracelen * ( 1 - tr.Fraction )
			local force = ( spring_power * ( self.ThrusterPoints[ i ].Spring or 1 ) ) * compression

			-- calculate angular
			local forcelinear, forceangular = phys:CalculateForceOffset(
				Vector( 0, 0, force * thruster_mass ),
				point
			)

			-- accumulate
			angular = angular + forceangular + angular_damping
			linear = linear + forcelinear + hover_damping

		-- is the contact fully inside a wall?
		elseif ( tr.Fraction == 0 ) then

			-- increment contacts
			self.Contacts = self.Contacts + 1

		end

	end

	-- don't apply the forces if we're not upright. ( we can flip upside down whilst in the air )
	if ( self.Contacts > 0 && !self:IsUpright( phys ) ) then

		return SIM_NOTHING

	elseif ( self:IsGrinding() ) then

		self.CanPitch = true

	elseif ( self.Contacts >= 1 ) then

		self.CanPitch = false

	end

	-- movement
	if ( IsValid( driver ) ) then

		local forward = phys:GetAngles():Forward()
		local right = phys:GetAngles():Right()
		forward.z = 0
		right.z = 0

		-- speeds
		local forward_speed = self:GetSpeed()
		local rotation_speed = self:GetTurnSpeed()
		local yaw_speed = self:GetYawSpeed()
		local pitch_speed = self:GetPitchSpeed()
		local roll_speed = self:GetRollSpeed()
		local jump_power = self:GetJumpPower()

		-- flag as not turning
		driver.IsTurning = false

		-- do rotational movement if we're on the ground.
		if ( self.Contacts >= 1 ) then

			local speed = 0

			-- they use the mouse to control the board, figure out rotation force
			if ( self.MouseControl == 1 ) then

				-- get angles
				local ang1 = phys:GetAngles()
				local ang2 = driver:GetAngles() --:GetAimVector():Angle()
				ang2:RotateAroundAxis( Vector( 0, 0, -1 ), self:GetBoardRotation() )

				-- get the difference between the 2 and normalize it
				local diff = math.NormalizeAngle( ang1.y - ang2.y )

				-- calculate the delta
				local delta = ( diff > 0 ) && 1 || -1
				-- calculate the speed
				speed = math.Clamp( ( 180 * delta ) - diff, -rotation_speed, rotation_speed )

				-- we are turning.
				if ( ( diff > 0 && diff < 150 ) or ( diff < 0 && diff > -150 ) ) then driver.IsTurning = true end

				if ( !driver:KeyDown( IN_FORWARD ) && !driver:KeyDown( IN_BACK ) ) then

					-- rotate left
					if ( driver:KeyDown( IN_MOVELEFT ) ) then

						local forcel, forcea = self:ApplySideForce( phys, forward_speed * 0.5, thruster_mass )
						angular = angular + forcea
						linear = linear + forcel + friction

					end

					-- rotate right
					if ( driver:KeyDown( IN_MOVERIGHT ) ) then

						local forcel, forcea = self:ApplySideForce( phys, ( forward_speed * 0.5 ) * -1, thruster_mass )
						angular = angular + forcea
						linear = linear + forcel + friction

					end

				end

			else

				if ( driver:KeyDown( IN_MOVELEFT ) ) then
					speed = rotation_speed
					driver.IsTurning = true
				end

				if ( driver:KeyDown( IN_MOVERIGHT ) ) then
					speed = -rotation_speed
					driver.IsTurning = true
				end


			end

			-- apply turning force
			local forcelinear, forceangular = phys:CalculateForceOffset(
				right * speed * thruster_mass,
				phys:GetPos() + forward * -24
				--phys:GetPos() + forward * -24 + up * 8 -- This causes the board to tilt its nose down or up while turning
			)

			angular = angular + forceangular

		else

			-- no more turning!
			driver.IsTurning = true

		end

		-- boosting
		if ( self:IsBoosting() ) then forward_speed = forward_speed * 1.5 end

		-- move forward
		if ( driver:KeyDown( IN_FORWARD ) && self.Contacts >= 1 ) then

			local forcel, forcea = self:ApplyForwardForce( phys, -forward_speed, thruster_mass )
			angular = angular + forcea
			linear = linear + forcel + friction

		end

		-- move backward
		if ( driver:KeyDown( IN_BACK ) && self.Contacts >= 1 ) then

			local forcel, forcea = self:ApplyForwardForce( phys, forward_speed, thruster_mass )
			angular = angular + forcea
			linear = linear + forcel + friction

		end

		-- grind?
		if ( driver:KeyDown( IN_DUCK ) or driver:KeyDown( IN_ATTACK2 ) ) then

			-- grinding destroys all forces
			angular = Vector( 0, 0, 0 )
			linear = Vector( 0, 0, 0 )

			-- update grinding
			if ( !self:IsGrinding() ) then self:SetGrinding( true ) end

		else

			-- update grinding
			if ( self:IsGrinding() ) then self:SetGrinding( false ) end

		end

		-- aerial control
		if ( self.Contacts == 0 or self:IsGrinding() ) then

			-- rolling
			if ( driver:KeyDown( IN_ATTACK ) ) then

				-- rotate left
				if ( driver:KeyDown( IN_MOVELEFT ) ) then

					local force = self:ApplyRollForce( phys, roll_speed, thruster_mass )
					angular = angular + force

				end

				-- rotate right
				if ( driver:KeyDown( IN_MOVERIGHT ) ) then

					local force = self:ApplyRollForce( phys, -roll_speed, thruster_mass )
					angular = angular + force

				end

			-- yaw
			else

				-- rotate left
				if ( driver:KeyDown( IN_MOVELEFT ) ) then

					local force = self:ApplyRotateForce( phys, yaw_speed, thruster_mass )
					angular = angular + force

				end

				-- rotate right
				if ( driver:KeyDown( IN_MOVERIGHT ) ) then

					local force = self:ApplyRotateForce( phys, -yaw_speed, thruster_mass )
					angular = angular + force

				end

			end

			-- pitch forward
			if ( driver:KeyDown( IN_FORWARD ) && self.CanPitch ) then

				local force = self:ApplyPitchForce( phys, -pitch_speed, thruster_mass )
				angular = angular + force

			end

			-- pitch back
			if ( driver:KeyDown( IN_BACK ) && self.CanPitch ) then

				local force = self:ApplyPitchForce( phys, pitch_speed, thruster_mass )
				angular = angular + force

			end

		end

		-- jump is handled via keypress since it was unresponsive here.
		if ( self.Jumped ) then

			-- current speed
			local speed = velocity:Length()

			-- fractional speed
			speed = speed / 575

			-- calculate speed sound
			jump_power = math.Clamp( jump_power * speed, 170, 300 ) / 5

			-- stopped jump
			self.Jumped = false

			self:EmitSound( self.JumpSoundFile )

			-- apply a jump force to each thruster
			for i = 1, thrusters do

				local point = self:GetThruster( i )
				local speed = velocity:Length()

				-- shift the jump point based on speed
				point = point + ( forward * ( speed * 0.01 ) )

				-- apply force
				local forcelinear, forceangular = phys:CalculateForceOffset( Vector( 0, 0, jump_power ) * thruster_mass, point )
				angular = angular + forceangular + angular_damping
				linear = linear + forcelinear + friction

			end

		end

	end

	-- apply friction
	linear = linear + ( friction * deltatime * ( self:IsGrinding() && 10 or 400 ) * ( ( 1 / thrusters ) * self.Contacts ) )

	-- damping
	angular = angular + angular_damping * deltatime * 750

	-- simuluate
	return angular, linear, SIM_GLOBAL_ACCELERATION

end

hook.Add( "KeyPress", "Hoverboard_KeyPress", function( pl, in_key )

	-- get the scripted vehicle
	local board = pl:GetNWEntity( "ScriptedVehicle" )

	-- make sure they are using the hoverboard
	if ( !IsValid( board ) or board:GetClass() != "modulus_hoverboard" ) then return end

	-- check if they are pressing the use key
	if ( in_key == IN_USE ) then

		-- remove them from board
		board:SetDriver( NULL )

		local phys = board:GetPhysicsObject()
		if ( IsValid( phys ) ) then

			-- get angle
			local ang = board:GetAngles()
			ang.r = 0
			ang:RotateAroundAxis( Vector( 0, 0, 1 ), board:GetBoardRotation() + 180 )

			-- kick forward (prevents players from getting stuck in board)
			phys:ApplyForceCenter( ang:Forward() * phys:GetMass() * 500 )

		end

		-- Delay next use
		board.NextUse = CurTime() + 1

	end

	-- Jump
	--if ( in_key == IN_JUMP && board.Contacts >= 3 && board.WaterContacts < 2 ) then
	if ( in_key == IN_JUMP && board.Contacts >= 2 && board.WaterContacts < 2 ) then board.Jumped = true end

	-- Boost
	if ( in_key == IN_SPEED && !board:IsBoosting() && board:Boost() == 100 ) then board:SetBoosting( true ) /* turn on boost */ end

end )

function ENT:Use( activator, caller )

	-- Has to be a player
	if ( !IsValid( activator ) or !activator:IsPlayer() ) then return end

	-- Make sure we are upright and not under water
	if ( !self:IsUpright() or self:WaterLevel() > 0 ) then return end

	self.NextUse = self.NextUse or 0

	-- Make sure its time to be used
	if ( CurTime() < self.NextUse ) then return end

	self.NextUse = CurTime() + 1 -- Delay the next use

	self:SetDriver( activator ) -- Set the driver

end

function ENT:Mount( pl )

	self:EmitSound( self.MountSoundFile )

	local ang = self:GetAngles()
	ang.r = 0
	ang:RotateAroundAxis( Vector( 0, 0, 1 ), 180 )
	ang:RotateAroundAxis( Vector( 0, 0, 1 ), self:GetBoardRotation() )
	pl:SetAngles( ang )
	pl:SetEyeAngles( ang )

end

function ENT:UnMount( pl )

	self:EmitSound( self.UnMountSoundFile )

	-- set player angle
	local ang = self:GetAngles()
	ang.r = 0
	ang:RotateAroundAxis( Vector( 0, 0, 1 ), self:GetBoardRotation() + 180 )
	pl:SetAngles( ang )
	pl:SetEyeAngles( ang )

	-- Try to figure out a good position for the player
	local pos = self:GetPos() + self:GetUp() * 8
	/*local newpos = Vector(0,0,0)

	local tr = util.TraceHull( {
		start = pos,
		endpos = pos,
		mins = pl:OBBMins(),
		maxs = pl:OBBMaxs(),
		filter = {
			self, pl, self.Hull, self.Avatar
		}
	} )

	if ( tr.Hit ) then
		ChatPrint( tr.Entity )
		//Entity(2):Kill()

		for id, vec in pairs( { Vector( 1, 0, 0 ), Vector( -1, 0, 0 ), Vector( 0, 1, 0 ), Vector( 0, -1, 0 ), Vector( 0, 0, 1 ), Vector( 0, 0, -1 ) } ) do

			local tr2 = util.TraceHull( {
				start = pos,
				endpos = pos + vec * 200,
				mins = pl:OBBMins(),
				maxs = pl:OBBMaxs(),
				filter = {
					self, pl, self.Hull, self.Avatar
				}
			} )

			local tr3 = util.TraceHull( {
				start = pos - vec * 200,
				endpos = tr2.HitPos,
				mins = pl:OBBMins(),
				maxs = pl:OBBMaxs()
			} )

			local tr4 = util.TraceHull( {
				start = tr3.HitPos - vec,
				endpos = tr3.HitPos - vec,
				mins = pl:OBBMins(),
				maxs = pl:OBBMaxs()
			} )

			if ( !tr4.Hit ) then
				pos = tr4.HitPos
				ChatPrint( "STOOPED" )
				newpos = newpos + Vector( tr4.HitPos.x * math.abs(vec.x),tr4.HitPos.y * math.abs(vec.y),tr4.HitPos.z * math.abs(vec.z) )
				//break
			end
		end
	end*/

	pl:SetPos( pos )
	--pl:SetPos( self:GetPos() - self:GetForward() * 64 )
	pl:SetMoveType( MOVETYPE_WALK )

end

hook.Add( "EntityTakeDamage", "Hoverboard_EntityTakeDamage", function( ent, dmginfo )

	local attacker = dmginfo:GetAttacker() -- get attacker

	-- make sure its a hoverboard
	if ( IsValid( attacker ) ) then

		local driver

		if ( attacker:GetClass() == "modulus_hoverboard" ) then

			-- get driver
			driver = attacker:GetDriver()

		elseif ( attacker:GetClass() == "modulus_hoverboard_hull" ) then

			-- get driver
			driver = attacker:GetOwner():GetDriver()

		end

		-- validate
		if ( IsValid( driver ) ) then

			-- change attacker
			dmginfo:SetAttacker( driver )

		end

	end

end )

function ENT:AddEffect( effect, pos, normal, scale )

	-- increment effect count
	local index = tonumber( self:GetEffectCount() ) or 0
	index = index + 1

	self:SetEffectCount( index )

	-- add new effect
	self:SetNetworkedString( "Effect" .. index, effect )
	self:SetNetworkedVector( "EffectPos" .. index, pos || Vector( 0, 0, 0 ) )
	self:SetNetworkedVector( "EffectNormal" .. index, normal || Vector( 0, 0, 1 ) )
	self:SetNetworkedFloat( "EffectScale" .. index, scale || 1 )

end
