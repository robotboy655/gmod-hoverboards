
local glow = Material( "modulus_hoverboard/glow" )
local trail = Material( "modulus_hoverboard/trail" )

function EFFECT:RemapValClamped( value, a, b, c, d )

	local v = math.Clamp( ( value - a ) / ( b - a ), 0, 1 ) -- clamp to 0/1

	return c + ( d - c ) * v -- remap

end

function EFFECT:Init( pos, normal, scale )

	self.Position = pos -- pos and scale are the only things that interest us

	-- trail points
	self.Points = {}
	self.NextPoint = UnPredictedCurTime() + 0.05

end

function EFFECT:Think( id )
	self.ID = id

	-- time to update?
	if ( self.NextPoint > UnPredictedCurTime() or self.Board:GetBoardVelocity() < 150 or self.Board:IsGrinding() ) then return end

	-- add new trail points
	self.Points[ #self.Points + 1 ] = {
		Position = self.Board:LocalToWorld( self.Position ),
		DieTime = UnPredictedCurTime() + 0.5,
	}

	-- destroy dead trail segments
	for i = #self.Points, 1, -1 do

		if ( self.Points[ i ].DieTime <= UnPredictedCurTime() ) then
			table.remove( self.Points, i ) -- die?
		end

	end

	self.NextPoint = UnPredictedCurTime() + 0.05 -- next update

end

function EFFECT:Render( )

	local count = #self.Points;

	-- not enough points to draw the trail
	if (  self.Board:IsGrinding() or self.Board:WaterLevel() > 0 ) then return end

	-- alpha
	local alpha = self:RemapValClamped( self.Board:GetBoardVelocity(), 150, 1000, 0, 255 )

	-- get trail color
	local color_vec = self.Board:GetTrailColor()
	local color = Color( color_vec.x, color_vec.y, color_vec.z, 255 )

	local recharge_color_vec = self.Board:GetTrailRechargeColor();
	local recharge_color = Color( recharge_color_vec.x, recharge_color_vec.y, recharge_color_vec.z, 255 )

	local boost_color_vec = self.Board:GetTrailBoostColor()
	local boost_color = Color( boost_color_vec.x, boost_color_vec.y, boost_color_vec.z, 255 )

	if ( self.Board:IsBoosting() ) then

		local percent = ( 100 - self.Board:Boost() ) / 100

		color = Color( Lerp( percent, boost_color.r, recharge_color.r ), Lerp( percent, boost_color.g, recharge_color.g ), Lerp( percent, boost_color.b, recharge_color.b ), 255 )

	elseif ( !self.Board:IsBoosting() and self.Board:Boost() < 100 ) then

		local percent = self.Board:Boost() / 100

		color = Color( Lerp( percent, recharge_color.r, color.r ), Lerp( percent, recharge_color.g, color.g ), Lerp( percent, recharge_color.b, color.b ), 255 )

	end

	local anchor = self.Board:LocalToWorld( self.Position )

	render.SetMaterial( glow )
	render.DrawSprite( anchor, 24 * self.Board:GetTrailScale(), 24 * self.Board:GetTrailScale(), Color( color.r, color.g, color.b, alpha * 0.5 ) )

	render.DrawSprite( anchor, math.Rand( 8, 10 ) * self.Board:GetTrailScale(), math.Rand( 8, 10 ) * self.Board:GetTrailScale(), Color( color.r, color.g, color.b, alpha ) )

	render.SetMaterial( trail )
	render.StartBeam( count + 1 )

	for i = 1, count do

		local seg = self.Points[ i ]
		local coord = ( 1 / count ) * ( i - 1 )
		local percent = math.Clamp( ( seg.DieTime - UnPredictedCurTime() ) / 0.5, 0, 1 )

		render.AddBeam( seg.Position, 12 * self.Board:GetTrailScale(), coord, Color( color.r, color.g, color.b, alpha * percent ) )

	end

	render.AddBeam( anchor, 12 * self.Board:GetTrailScale(), 1, Color( color.r, color.g, color.b, alpha ) )

	render.EndBeam()

	if ( GetConVarNumber( "hoverboard_lights" ) == 0 ) then return end

	local SaberLight = DynamicLight( self.Board:EntIndex() + self.ID + 566 ) -- 655 is used on lightsabers
	if ( SaberLight ) then
		--local ent = self.Board
		SaberLight.Pos = anchor
		SaberLight.r = color.r
		SaberLight.g = color.g
		SaberLight.b = color.b
		SaberLight.Brightness = 1
		SaberLight.Size = 256
		SaberLight.Decay = 0
		SaberLight.DieTime = CurTime() + 0.1
	end

end
