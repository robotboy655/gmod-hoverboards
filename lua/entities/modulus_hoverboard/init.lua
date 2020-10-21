
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

ENT.MountSoundFile = "buttons/button9.wav"
ENT.UnMountSoundFile = "buttons/button19.wav"
ENT.JumpSoundFile = "weapons/airboat/airboat_gun_energy1.wav"

function ENT:Precache()

	util.PrecacheSound( self.MountSoundFile )
	util.PrecacheSound( self.UnMountSoundFile )
	util.PrecacheSound( self.JumpSoundFile )

end

function ENT:Initialize()

	self:Precache()

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetUseType( ONOFF_USE )

	self.WaterContacts = 0
	self.Contacts = 0
	self.MouseControl = true
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

function ENT:SetControls( bMouse )

	self.MouseControl = tobool( bMouse )

end

function ENT:UpdateTransmitState()

	return TRANSMIT_ALWAYS

end

function ENT:SetDriver( pl )

	if ( !IsValid( self.Avatar ) ) then self:CreateAvatar() end
	self.Avatar:SetPlayer( pl )

	local driver = self:GetDriver()

	if ( IsValid( driver ) ) then

		if ( !IsValid( pl ) or GetConVarNumber( "sv_hoverboard_cansteal" ) == 1 ) then -- check if we should boot the driver

			driver:SetNWEntity( "ScriptedVehicle", NULL ) -- clear it's scripted vehicle

			self:UnMount( driver ) -- unmount

			--driver:SetMoveType( driver.OldMoveType ) -- restore movetype
			driver:SetMoveType( MOVETYPE_WALK ) -- restore movetype
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

		 -- don't allow us to mount if we already have a scripted vehicle
		if ( IsValid( pl:GetNWEntity( "ScriptedVehicle" ) ) ) then return end

		-- set scripted vehicle
		pl:SetNWEntity( "ScriptedVehicle", self )

		-- store our old movetype and prevent us from moving
		--pl.OldMoveType = pl:GetMoveType()
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

	return up.z >= 0.33

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
			mask = bit.bor( MASK_SOLID , MASK_WATER )
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
		--local up = phys:GetAngles():Up()
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
			if ( self.MouseControl ) then

				-- get angles
				local ang1 = phys:GetAngles()
				local ang2 = driver:GetAimVector():Angle()
				ang2:RotateAroundAxis( Vector( 0, 0, -1 ), self:GetBoardRotation() )

				-- get the difference between the 2 and normalize it
				local diff = math.NormalizeAngle( ang1.y - ang2.y )

				-- calculate the delta
				local delta = ( diff > 0 ) && 1 or -1

				-- calculate the speed, x3 to make it a lot more responsive at higher Turn attribute values
				speed = ( 180 * delta ) - diff
				speed = math.Clamp( speed * 3, -rotation_speed, rotation_speed )

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

			-- No pitch or roll when turning please
			forceangular.r = 0
			forceangular.p = 0
			angular = angular + forceangular

		else

			-- no more turning!
			driver.IsTurning = true

		end

		-- Boosting
		if ( self:IsBoosting() ) then forward_speed = forward_speed * 1.5 end

		-- Move forward
		if ( driver:KeyDown( IN_FORWARD ) && self.Contacts >= 1 ) then

			local forcel, forcea = self:ApplyForwardForce( phys, -forward_speed, thruster_mass )
			angular = angular + forcea
			linear = linear + forcel + friction

		end

		-- Move backward
		if ( driver:KeyDown( IN_BACK ) && self.Contacts >= 1 ) then

			local forcel, forcea = self:ApplyForwardForce( phys, forward_speed, thruster_mass )
			angular = angular + forcea
			linear = linear + forcel + friction

		end

		-- Grinding?
		if ( driver:KeyDown( IN_DUCK ) or driver:KeyDown( IN_ATTACK2 ) ) then

			-- grinding destroys all forces
			angular = Vector( 0, 0, 0 )
			linear = Vector( 0, 0, 0 )

			if ( !self:IsGrinding() ) then self:SetGrinding( true ) end

		else

			if ( self:IsGrinding() ) then self:SetGrinding( false ) end

		end

		-- Aerial control
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

			self.Jumped = false

			self:EmitSound( self.JumpSoundFile )

			-- Jump force
			local jump_force = ( 170 + math.Clamp( jump_power, 0, 300 ) ) * 0.2

			-- apply a jump force to each thruster
			for i = 1, thrusters do

				local point = self:GetThruster( i )

				-- shift the jump point based on speed
				point = point + ( forward * ( velocity:Length() * 0.01 ) )

				-- apply force
				local forcelinear, forceangular = phys:CalculateForceOffset( Vector( 0, 0, jump_force ) * thruster_mass, point )
				angular = angular + forceangular + angular_damping
				linear = linear + forcelinear + friction

			end

		end

	end

	-- Fixes hoverboard speeding up unexpectedly when on 2 thrusters
	local fric_contacts = 0
	if ( self.Contacts > 0 ) then fric_contacts = thrusters end

	-- Apply friction
	linear = linear + ( friction * deltatime * ( self:IsGrinding() && 10 or 400 ) * ( ( 1 / thrusters ) * fric_contacts ) )

	-- Damping
	angular = angular + angular_damping * deltatime * 750

	return angular, linear, SIM_GLOBAL_ACCELERATION

end

-- This is not as smooth as it could be if done clientside
hook.Add( "SetupMove", "Hoverboards_ViewDistance", function( ply, mv, cmd )

	local board = ply:GetNWEntity( "ScriptedVehicle" )
	if ( !IsValid( board ) or board:GetClass() != "modulus_hoverboard" or cmd:GetMouseWheel() == 0 ) then return end

	board:SetViewDistance( math.Clamp( board:GetViewDistance() + -cmd:GetMouseWheel() * 10, 64, 256 ) )

end )

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
	if ( in_key == IN_JUMP && board.Contacts >= 2 && ( board.WaterContacts < 2 or GetConVarNumber( "sv_hoverboard_water_jump" ) != 0 ) ) then board.Jumped = true end

	-- Boost
	if ( in_key == IN_SPEED && !board:IsBoosting() && board:Boost() == 100 ) then board:SetBoosting( true ) /* turn on boost */ end

end )

function ENT:Use( activator, caller )

	-- Has to be a player
	if ( !IsValid( activator ) or !activator:IsPlayer() ) then return end

	-- We are upside down, try to flip
	if ( !self:IsUpright() ) then
		if ( IsValid( self:GetPhysicsObject() ) ) then self:GetPhysicsObject():AddAngleVelocity( Vector( 0, 4800, 0 ) ) end
		return
	end

	-- Make sure we are not under water
	if ( self:WaterLevel() > 0 ) then return end

	self.NextUse = self.NextUse or 0

	-- Make sure its time to be used
	if ( CurTime() < self.NextUse ) then return end

	self.NextUse = CurTime() + 1 -- Delay the next use

	self:SetDriver( activator ) -- Set the driver

end

function ENT:Mount( pl )

	self:EmitSound( self.MountSoundFile )

	-- Set player angles
	local ang = self:GetAngles()
	ang.r = 0
	ang:RotateAroundAxis( Vector( 0, 0, 1 ), 180 )
	ang:RotateAroundAxis( Vector( 0, 0, 1 ), self:GetBoardRotation() )

	pl:SetAngles( ang )
	pl:SetEyeAngles( ang )

end

local function IsPlayerSpotGood( pl, pos )

	-- Can we stand in this spot?
	local mins, maxs = pl:GetHull()
	local tr = util.TraceHull( {
		start = pos, endpos = pos,
		mins = mins, maxs = maxs,
		filter = pl
	} )
	if ( !tr.Hit ) then return true end

	-- Can we crouch in this spot?
	local minsD, maxsD = pl:GetHullDuck()
	local trD = util.TraceHull( {
		start = pos, endpos = pos,
		mins = minsD, maxs = maxsD,
		filter = pl
	} )
	if ( !trD.Hit ) then
		pl:AddFlags( FL_DUCKING )
		return true
	end

	return false

end

function ENT:UnMount( pl )

	self:EmitSound( self.UnMountSoundFile )

	-- Set player angles
	local ang = self:GetAngles()
	ang.r = 0
	ang:RotateAroundAxis( Vector( 0, 0, 1 ), self:GetBoardRotation() + 180 )

	pl:SetAngles( ang )
	pl:SetEyeAngles( ang )

	-- We already good
	if ( IsPlayerSpotGood( pl, pl:GetPos() ) ) then return end

	-- Try to figure out a good position for the player
	local pos = self:GetPos()
	if ( IsPlayerSpotGood( pl, pos ) ) then pl:SetPos( pos ) return end

	pos = self:GetPos() + self:GetUp() * 8
	if ( IsPlayerSpotGood( pl, pos ) ) then pl:SetPos( pos ) return end

	-- Try to place the player in every direction from the board
	pos = self:GetPos()
	local mins, maxs = pl:GetHullDuck() -- Assume worst case
	for id, vec in pairs( { self:GetForward(), -self:GetForward(), self:GetRight(), -self:GetRight(), self:GetUp(), -self:GetUp(), Vector( 1, 0, 0 ), Vector( -1, 0, 0 ), Vector( 0, 1, 0 ), Vector( 0, -1, 0 ), Vector( 0, 0, 1 ), Vector( 0, 0, -1 ) } ) do

		local tr = util.TraceHull( {
			start = pos,
			endpos = pos + vec * 100,
			mins = mins,
			maxs = maxs,
			filter = {
				self, pl, self.Hull, self.Avatar
			}
		} )

		if ( IsPlayerSpotGood( pl, tr.HitPos ) ) then
			return pl:SetPos( tr.HitPos )
		end
	end

	-- print( "FOUND NO POS" )
	-- TODO: Kill?
	-- ply:TakeDamage( ply:Health() )

end

hook.Add( "EntityTakeDamage", "Hoverboard_EntityTakeDamage", function( ent, dmginfo )

	local inflictor = dmginfo:GetInflictor()
	if ( IsValid( inflictor ) && GetConVarNumber( "sv_hoverboard_allow_damage" ) == 0
		&& ( inflictor:GetClass() == "modulus_hoverboard" or inflictor:GetClass() == "modulus_hoverboard_hull" ) ) then

		dmginfo:SetDamage( 0 )

	end

	local attacker = dmginfo:GetAttacker()
	if ( !IsValid( attacker ) ) then return end

	local driver = NULL

	if ( attacker:GetClass() == "modulus_hoverboard" ) then

		driver = attacker:GetDriver()

	elseif ( attacker:GetClass() == "modulus_hoverboard_hull" ) then

		driver = attacker:GetOwner():GetDriver()

	end

	if ( IsValid( driver ) ) then

		dmginfo:SetAttacker( driver )

	end

end )

function ENT:AddEffect( effect, pos, normal, scale )

	-- Increment effect count
	local index = self:GetEffectCount() + 1
	self:SetEffectCount( index )

	-- Add new effect
	self:SetNWString( "Effect" .. index, effect )
	self:SetNWVector( "EffectPos" .. index, pos or Vector( 0, 0, 0 ) )
	self:SetNWVector( "EffectNormal" .. index, normal or Vector( 0, 0, 1 ) )
	self:SetNWFloat( "EffectScale" .. index, scale or 1 )

end
