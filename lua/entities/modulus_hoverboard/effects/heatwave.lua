
local glow = Material( "modulus_hoverboard/glow" )

function EFFECT:Init( pos, normal, scale )

	self.Position = pos
	self.Scale = scale
	self.Normal = normal:Angle()

	self.Emitter = ParticleEmitter( self.Board:GetPos() )

end

function EFFECT:ShouldRender()
	if ( self.Board:IsGrinding() || self.Board:GetUp().z < 0.33 || self.Board:WaterLevel() > 0 ) then
		return false
	end

	return true
end

function EFFECT:Think()

	if ( !self:ShouldRender() ) then return end

	local particle = self.Emitter:Add( "sprites/heatwave", self.Board:LocalToWorld( self.Position ) )
	particle:SetDieTime( math.Rand( 0.05, 0.15 ) )
	particle:SetColor( 255, 255, 255 )
	particle:SetStartSize( 8 * self.Scale )
	particle:SetEndSize( math.Rand( 4, 8 ) * self.Scale )
	particle:SetStartAlpha( 255 )
	particle:SetEndAlpha( 255 )
	particle:SetVelocity( self.Board:WorldToLocalAngles( self.Normal ):Forward() * math.Rand( 50, 150 ) + VectorRand() * math.Rand( 10, 25 ) )
	particle:SetRollDelta( math.Rand( -2, 2 ) )
	particle:SetCollide( true )
	particle:SetBounce( 0.2 )

end

function EFFECT:Render()

	if ( !self:ShouldRender() ) then return end

	local timer = math.max( 0, math.sin( UnPredictedCurTime() ) )
	local timer2 = math.max( 0, math.sin( UnPredictedCurTime() * 2 ) )
	local anchor = self.Board:LocalToWorld( self.Position )

	render.SetMaterial( glow )
	render.DrawSprite( anchor, 48 * self.Scale, 48 * self.Scale, Color( 255, 128, 0, 60 ) )

	render.DrawSprite( anchor, 48 * timer, 48 * timer, Color( 255, 128, 0, 20 ) )

	render.DrawSprite( anchor, 32 * timer2, 32 * timer2, Color( 255, 128, 0, 20 ) )

end
