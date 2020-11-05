
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()

	self:DrawShadow( false )
	self:SetModel( self.Model )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:SetCollisionBounds( Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) )

end

function ENT:UpdateTransmitState()

	return TRANSMIT_ALWAYS

end

function ENT:SetPlayer( pl )

	self:SetNWEntity( "Player", pl )

	if ( IsValid( pl ) && pl:IsPlayer() ) then

		self.Model = pl:GetModel()
		self:SetModel( self.Model )
		self:SetSkin( pl:GetSkin() )
		self.GetPlayerColor = function() return pl:GetPlayerColor() end

		for i = 0, pl:GetNumBodyGroups() - 1 do self:SetBodygroup( i, pl:GetBodygroup( i ) ) end

	end

	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:SetCollisionBounds( Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) )

	self:NextThink( CurTime() )

end

function ENT:SetBoard( ent )

	self:SetOwner( ent )
	self:SetNWEntity( "Board", ent )

	self:NextThink( CurTime() )

end
