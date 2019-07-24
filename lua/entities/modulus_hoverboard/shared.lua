
ENT.Type = "vehicle"
ENT.Base = "base_anim"
ENT.PrintName = "Hoverboard"
ENT.Spawnable = false

ENT.ThrusterPoints = {
	{ Pos = Vector( -24, 13, 24 ) },
	{ Pos = Vector( 24, 13, 20 ) }, -- was 24 on z
	{ Pos = Vector( -24, -13, 24 ) },
	{ Pos = Vector( 24, -13, 20 ) }, -- was 24 on z

	{ Pos = Vector( -48, 0, 24 ), Diff = 24, Spring = 3 }, -- was 0 on z
}

function ENT:SetupDataTables()

	self:NetworkVar( "Float", 0, "BoostShake" )
	self:NetworkVar( "Float", 1, "BoardVelocity" )
	self:NetworkVar( "Float", 2, "MaxLength" )
	self:NetworkVar( "Float", 3, "TrailScale" )
	self:NetworkVar( "Float", 4, "BoardRotation" )

	self:NetworkVar( "String", 0, "HoverHeight" ) -- Stupid limits!
	self:NetworkVar( "String", 1, "ViewDistance" )
	self:NetworkVar( "String", 2, "EffectCount" )

	self:NetworkVar( "Bool", 0, "DarkInner" )

	self:NetworkVar( "Vector", 0, "TrailColor" )
	self:NetworkVar( "Vector", 1, "TrailBoostColor" )
	self:NetworkVar( "Vector", 2, "TrailRechargeColor" )

	self:NetworkVar( "Entity", 0, "ScriptedVehicle" )

end

function ENT:GetDriver()
	return self:GetOwner()
end

hook.Add( "ShouldDrawLocalPlayer", "hoverboards_draw", function()
	if ( IsValid( LocalPlayer():GetNWEntity( "ScriptedVehicle" ) ) ) then return false end
end )

hook.Add( "CalcView", "__111hoverboards_calcview", function( pl, pos, ang, fov )

	local ent = pl:GetNWEntity( "ScriptedVehicle" )

	pl.ShouldDisableLegs = false
	if ( !IsValid( ent ) || ent:GetClass() != "modulus_hoverboard" ) then return end
	if ( pl:InVehicle() || !pl:Alive() || pl:GetViewEntity() != pl ) then return end
	pl.ShouldDisableLegs = true

	--ang:RotateAroundAxis( Vector( 0, 0, 1 ), ent:GetBoardRotation() )
	local dir = ang:Forward()

	local pos = ent:GetPos() + Vector( 0, 0, 64 ) - ( dir * tonumber( ent:GetViewDistance() ) )
	local speed = ent:GetVelocity():Length() - 500

	-- shake their view
	if ( ent:IsBoosting() && speed > 0 && ent:GetBoostShake() == 1 ) then

		local power = 14 * ( speed / 700 )

		local x = math.Rand( -power, power ) * 0.1
		local y = math.Rand( -power, power ) * 0.1
		local z = math.Rand( -power, power ) * 0.1

		pos = pos + Vector( x, y, z )

	end

	-- trace to keep it out of the walls
	local tr = util.TraceHull( {
		start = ent:GetPos() + Vector( 0, 0, 64 ),
		endpos = pos,
		filter = { ent, pl, ent:GetNWEntity( "Avatar", NULL ) },
		mask = MASK_NPCWORLDSTATIC,
		mins = Vector( -4, -4, -4 ),
		maxs = Vector( 4, 4, 4 )
	} )

	-- setup view
	local view = {
		origin = tr.HitPos,
		angles = dir:Angle(),
		fov = fov,
	}

	return view

end )

function ENT:IsGrinding()

	return self:GetNWBool( "Grinding", false )

end

function ENT:Boost()

	return self:GetNWInt( "Boost", 0 )

end

function ENT:IsBoosting()

	return self:GetNWBool( "Boosting", false )

end

function ENT:GetThruster( index )

	local pos = self:LocalToWorld( self.ThrusterPoints[ index ].Pos )

	-- get distance and dir
	local dist = ( self:GetPos() - pos ):Length()
	local dir = ( pos - self:GetPos() ):GetNormalized()

	-- rotate
	dir = dir:Angle()
	dir:RotateAroundAxis( self:GetUp(), self:GetBoardRotation() )
	dir = dir:Forward()

	-- return
	return self:GetPos() + dir * dist

end

hook.Add( "Move", "Hoverboard_Move", function( pl, mv )

	-- get the scripted vehicle
	local board = pl:GetNWEntity( "ScriptedVehicle" )

	-- make sure they are using the hoverboard
	if ( !IsValid( board ) || board:GetClass() != "modulus_hoverboard" ) then return end

	-- set their origin
	mv:SetOrigin( board:GetPos() )

	-- prevent their movement
	return true

end )

hook.Add( "UpdateAnimation", "Hoverboard_UpdateAnimation", function( pl )

	local board = pl:GetNWEntity( "ScriptedVehicle" ) -- get the scripted vehicle

	-- make sure they are using the hoverboard
	if ( !IsValid( board ) || board:GetClass() != "modulus_hoverboard" ) then return end

	-- copy pose parameters
	local pose_params = { "head_pitch", "head_yaw", "body_yaw", "aim_yaw", "aim_pitch" }
	for _, param in pairs( pose_params ) do

		if ( IsValid( board.Avatar ) ) then

			local val = pl:GetPoseParameter( param )
			board.Avatar:SetPoseParameter( param, val )

		end

	end

end )
