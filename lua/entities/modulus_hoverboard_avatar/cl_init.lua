
include( "shared.lua" )

function ENT:Draw( flags )

	if ( !IsValid( self:GetNWEntity( "Board" ) ) or !IsValid( self:GetNWEntity( "Board" ):GetDriver() ) or !IsValid( self:GetNWEntity( "Player" ) ) ) then return end

	local ply = self:GetNWEntity( "Player" )

	self.GetPlayerColor = function()
		if ( IsValid( ply ) or ply.GetPlayerColor ) then
			return ply:GetPlayerColor()
		else
			return Vector( 1, 1, 1 )
		end
	end

	self:DrawModel( flags )

end

function ENT:DrawTranslucent( flags )

	self:Draw( flags )

end
