
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

	self:NetworkVar( "Float", 0, "BoardVelocity" )
	self:NetworkVar( "Float", 1, "MaxLength" )
	self:NetworkVar( "Float", 2, "TrailScale" )
	self:NetworkVar( "Float", 3, "BoardRotation" )
	self:NetworkVar( "Float", 4, "HoverHeight" )
	self:NetworkVar( "Float", 5, "ViewDistance" )

	self:NetworkVar( "Int", 0, "EffectCount" )

	self:NetworkVar( "Bool", 0, "BoostShake" )

	self:NetworkVar( "Vector", 0, "TrailColor" )
	self:NetworkVar( "Vector", 1, "TrailBoostColor" )
	self:NetworkVar( "Vector", 2, "TrailRechargeColor" )

end

function ENT:GetDriver()
	return self:GetOwner()
end

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

hook.Add( "PlayerNoClip", "Hoverboard_DisallowOnboardNoclip", function( ply, desiredState )

	local board = ply:GetNWEntity( "ScriptedVehicle" )
	if ( !IsValid( board ) || board:GetClass() != "modulus_hoverboard" ) then return end

	-- Do not allow to disable noclip on the board
	-- Other mods will probably mess this up, but its no big deal
	return false

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
