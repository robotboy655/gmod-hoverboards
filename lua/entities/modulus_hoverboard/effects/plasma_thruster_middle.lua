
local plasma = Material( "effects/strider_muzzle" )
local refract = Material( "sprites/heatwave" )

function EFFECT:Init( pos, normal, scale )

	self.Position = pos
	self.Scale = scale
	self.Normal = normal:Angle()

	self.Emitter = ParticleEmitter( self.Board:GetPos() )

end

function EFFECT:ShouldRender( )

	if ( self.Board:IsGrinding() || self.Board:GetUp().z < 0.33 || self.Board:WaterLevel() > 0 ) then return false end

	return true

end

function EFFECT:Think( )

end

function EFFECT:Render( )

	if ( !self:ShouldRender() ) then return end

	local anchor = self.Board:LocalToWorld( self.Position )

	local normal = self.Board:LocalToWorldAngles( self.Normal ):Forward()
	anchor = anchor + normal * 2.5

	render.SetMaterial( refract )
	render.DrawSprite( anchor, 4 * math.Rand( 1, 1.5 ), 4 * math.Rand( 1, 1.5 ), Color( 128, 200, 255, 255 ) )

	local scroll = UnPredictedCurTime() * -20

	render.SetMaterial( plasma )

	scroll = scroll * 0.9
	render.StartBeam( 3 )
		render.AddBeam( anchor, 3, scroll, Color( 0, 255, 255, 255 ) )
		render.AddBeam( anchor + normal * 8, 3, scroll + 0.01, Color( 255, 255, 255, 255 ) )
		render.AddBeam( anchor + normal * 12, 3, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.9
	render.StartBeam( 3 )
		render.AddBeam( anchor, 3, scroll, Color( 0, 255, 255, 255 ) )
		render.AddBeam( anchor + normal * 3, 3, scroll + 0.01, Color( 255, 255, 255, 255 ) )
		render.AddBeam( anchor + normal * 6, 3, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()

	scroll = scroll * 0.9
	render.StartBeam( 3 )
		render.AddBeam( anchor, 3, scroll, Color( 0, 255, 255, 255) )
		render.AddBeam( anchor + normal * 3, 3, scroll + 0.01, Color( 255, 255, 255, 255) )
		render.AddBeam( anchor + normal * 6, 3, scroll + 0.02, Color( 0, 255, 255, 0) )
	render.EndBeam()

end
