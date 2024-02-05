
include( "shared.lua" )

ENT.RenderGroup = RENDERGROUP_BOTH

local glow = Material( "modulus_hoverboard/glow" )
local trail = Material( "modulus_hoverboard/trail" )

local g_HoverEffects = {}

local effectfiles = file.Find( "entities/modulus_hoverboard/effects/*.lua", "LUA" )
for _, filename in pairs( effectfiles ) do

	local old_effect = EFFECT

	EFFECT = {}

	function EFFECT:new()

		local obj = {}
		setmetatable( obj, self )
		self.__index = self

		return obj

	end

	include( "effects/" .. filename )

	local _, _, effectname = string.find( filename, "([%w_]*)%.lua" ) -- store

	g_HoverEffects[ effectname ] = EFFECT

	EFFECT = old_effect -- restore

end

function ENT:Initialize()

	-- hover sound
	self.HoverSoundFile = "weapons/gauss/chargeloop.wav"
	self.HoverSound = CreateSound( self, self.HoverSoundFile )
	self.HoverSoundPlaying = false

	-- grind soud
	self.GrindSoundFile = "physics/metal/metal_grenade_scrape_smooth_loop1.wav"
	self.GrindSound = CreateSound( self, self.GrindSoundFile )
	self.GrindSoundPlaying = false
	self.GrindSoundTime = 0

	-- boost sound
	self.BoostOffSoundFile = "npc/scanner/scanner_nearmiss1.wav"
	self.BoostOnSoundFile = "npc/scanner/scanner_nearmiss2.wav"
	self.BoostSoundFile = "ambient/levels/labs/teleport_rings_loop2.wav"
	self.BoostSound = CreateSound( self, self.BoostSoundFile )
	self:SetNWVarProxy( "Boosting", self.BoostStateChanged )

	-- effects list
	self.Effects = {}
	self.EffectsInitailized = false

	-- setup
	--self:SetShouldDrawInViewMode( true ) FIXME
	self:SetRenderBounds( Vector( -24, -8, -16 ), Vector( 24, 8, 16 ) )

end

function ENT:BoostStateChanged( name, oldvalue, newvalue )
	if !IsValid( self ) then return end

	-- check value
	if ( oldvalue == newvalue ) then return newvalue end

	-- handle t
	if ( newvalue ) then

		-- start sounds
		self.BoostSound:Play()
		self:EmitSound( self.BoostOnSoundFile )

	else

		-- stop sounds
		self.BoostSound:Stop()
		self:EmitSound( self.BoostOffSoundFile )

	end

	return newvalue

end

function ENT:OnRemove()

	self.HoverSound:Stop()
	self.GrindSound:Stop()
	self.BoostSound:Stop()

end

function ENT:Think()

	-- check grind time
	if ( self:GetNWFloat( "GrindSoundTime" ) > CurTime() ) then

		-- not playing
		if ( !self.GrindSoundPlaying ) then

			-- play it
			self.GrindSound:Play()
			self.GrindSoundPlaying = true

		end

	else

		-- still playing
		if ( self.GrindSoundPlaying ) then

			-- stop
			self.GrindSound:Stop()
			self.GrindSoundPlaying = false

		end

	end

	-- check sound is playing
	if ( !self.HoverSoundPlaying and !self:IsGrinding() ) then

		-- setup sound
		self.HoverSound:SetSoundLevel( 60 )
		self.HoverSound:Play()
		self.HoverSoundPlaying = true

	elseif ( self.HoverSoundPlaying and self:IsGrinding() ) then

		-- stop playing
		self.HoverSound:Stop()
		self.HoverSoundPlaying = false

	else

		if ( self:WaterLevel() == 0 ) then

			-- current speed
			local speed = self:GetBoardVelocity()

			-- fractional speed
			speed = speed / 700

			-- calculate speed sound
			local soundspeed = math.Clamp( 80 + ( speed * 55 ), 80, 160 )

			-- update
			self.HoverSound:ChangePitch( soundspeed, 0 )

		else

			self.HoverSound:ChangePitch( 0, 0 )

		end

	end

	-- check sound
	if ( self.HoverSoundPlaying and self:GetUp().z < 0.33 ) then

		-- stop sound
		self.HoverSound:Stop()
		self.HoverSoundPlaying = false

	end

	-- received my effects?
	if ( !self.EffectsInitailized and tonumber( self:GetEffectCount() ) ) then

		-- all done?
		local done = true

		-- initialize each effect
		for i = 1, tonumber( self:GetEffectCount() ) do

			-- was this effect initialized?
			if ( !self.Effects[ i ] ) then

				-- have all the attributes of it?
				if ( !self:GetNWString( "Effect" .. i, false ) or !self:GetNWVector( "EffectPos" .. i, false ) or
					!self:GetNWVector( "EffectNormal" .. i, false ) or !self:GetNWFloat( "EffectScale" .. i, false ) ) then

					-- not done, this effect isn't here yet
					done = false

				else

					-- get the effect name
					local effectname = self:GetNWString( "Effect" .. i )
					if ( !g_HoverEffects[ effectname ] ) then error( "Couldn't init effect " .. effectname ) return end
					-- load a new effect
					local effect = g_HoverEffects[ effectname ]:new()

					-- init
					effect.Board = self
					effect:Init(
						self:GetNWVector( "EffectPos" .. i ),
						self:GetNWVector( "EffectNormal" .. i ),
						self:GetNWFloat( "EffectScale" .. i )
					)

					-- add
					self.Effects[ i ] = effect

				end

			end

		end

		-- say we inited the effects
		self.EffectsInitailized = done

	end

	-- run effect think
	for _, effect in pairs( self.Effects ) do effect:Think( _ ) end

	-- think
	self:NextThink( UnPredictedCurTime() )
	return true

end

function ENT:Draw( flags )

	self:DrawModel( flags )

	if ( halo.RenderedEntity() == self ) then return end

	for _, effect in pairs( self.Effects ) do effect:Render() end

	if ( GetConVarNumber( "cl_hoverboard_developer" ) == 1 ) then

		-- for each hover point
		for i = 1, #self.ThrusterPoints do

			--local point = phys:LocalToWorld( self.ThrusterPoints[ i ].Pos )
			local point = self:GetThruster( i )

			local tracelen = tonumber( self:GetHoverHeight() ) - ( self.ThrusterPoints[ i ].Diff or 0 )

			-- trace for solid
			local trace = {
				start = point,
				endpos = point - Vector( 0, 0, tracelen ),
				mask = MASK_NPCWORLDSTATIC

			}
			local tr = util.TraceLine( trace )

			local color = Color( 128, 255, 128, 255 )
			if ( tr.Hit ) then
				color = Color( 255, 128, 128, 255 )
			end

			local scale = ( self.ThrusterPoints[ i ].Spring or 1 ) * 0.5
			local sprite = 16 * scale
			local beam = 4 * scale

			-- render
			cam.IgnoreZ( true )
			render.SetMaterial( glow )
			render.DrawSprite( point, sprite, sprite, color )
			render.DrawSprite( tr.HitPos, sprite, sprite, color )
			render.SetMaterial( trail )
			render.DrawBeam( point, tr.HitPos, beam, 0, 1, color )
			cam.IgnoreZ( false )

		end

	end

end

function ENT:DrawTranslucent( flags )

	self:Draw( flags )

end

local blocked = {
	"phys_swap",
	"slot",
	"invnext",
	"invprev",
	"lastinv",
	"gmod_tool",
	"gmod_toolmode"
}
hook.Add( "PlayerBindPress", "Hoverboard_PlayerBindPress", function( pl, bind, pressed )

	local board = pl:GetNWEntity( "ScriptedVehicle" )

	-- make sure they are using the hoverboard
	if ( !IsValid( board ) or board:GetClass() != "modulus_hoverboard" ) then return end

	-- loop
	for _, block in pairs( blocked ) do

		-- found?
		if ( bind:find( block ) ) then return true --[[ block ]] end

	end

end )

hook.Add( "HUDPaint", "Hoverboard_HUDPaint", function()

	-- check developer
	if ( GetConVarNumber( "cl_hoverboard_developer" ) == 1 ) then

		-- trace
		local tr = LocalPlayer():GetEyeTrace()

		-- check for board
		if ( IsValid( tr.Entity ) and tr.Entity:GetClass() == "modulus_hoverboard" ) then

			local pos = tr.Entity:WorldToLocal( tr.HitPos ) -- get coordinates
			local text = ("Coords: %s"):format( tostring( pos ) ) -- build string

			-- draw text
			draw.SimpleText( text, "Default",
				ScrW() * 0.5, ( ScrH() * 0.5 ) + 100,
				Color( 255, 255, 255, 255 ),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
			)

		end

	end

end )

hook.Add( "ShouldDrawLocalPlayer", "hoverboards_draw", function()
	if ( IsValid( LocalPlayer():GetNWEntity( "ScriptedVehicle" ) ) ) then return false end
end )

local ClientsideViewDistance = 0
local camMins, camMaxs = Vector( -4, -4, -4 ), Vector( 4, 4, 4 )
hook.Add( "CalcView", "__111hoverboards_calcview", function( pl, campos, ang, fov )

	local ent = pl:GetNWEntity( "ScriptedVehicle" )

	pl.ShouldDisableLegs = false -- For some legs mod?
	if ( !IsValid( ent ) or ent:GetClass() != "modulus_hoverboard" ) then return end
	if ( pl:InVehicle() or !pl:Alive() or pl:GetViewEntity() != pl ) then return end
	pl.ShouldDisableLegs = true

	-- Smooth the view distance
	if ( ClientsideViewDistance <= 0 ) then ClientsideViewDistance = ent:GetViewDistance() end

	local change = math.max( math.abs( ClientsideViewDistance - ent:GetViewDistance() ) / 20, 0.1 )
	ClientsideViewDistance = math.Approach( ClientsideViewDistance, ent:GetViewDistance(), change )

	-- Camera position
	local tr_up = util.TraceHull( {
		start = ent:GetPos(),
		endpos = ent:GetPos() + Vector( 0, 0, 64 ),
		filter = { ent, pl },
		mask = MASK_NPCWORLDSTATIC,
		mins = camMins,
		maxs = camMaxs
	} )

	local dir = ang:Forward()
	local origin = tr_up.HitPos
	local pos = origin - ( dir * ClientsideViewDistance )

	-- Shake their view
	local speed = ent:GetVelocity():Length() - 500
	if ( ent:IsBoosting() and speed > 0 and ent:GetBoostShake() ) then

		local power = 14 * ( speed / 700 )

		local x = math.Rand( -power, power ) * 0.1
		local y = math.Rand( -power, power ) * 0.1
		local z = math.Rand( -power, power ) * 0.1

		pos = pos + Vector( x, y, z )

	end

	-- Keep the camera outside of walls
	local tr = util.TraceHull( {
		start = origin,
		endpos = pos,
		filter = { ent, pl },
		mask = MASK_NPCWORLDSTATIC,
		mins = camMins,
		maxs = camMaxs
	} )

	-- We are too close to the camera from this point of view, try tracing from the board
	if ( tr.Fraction < 0.01 ) then
		tr = util.TraceHull( {
			start = ent:GetPos(),
			endpos = pos,
			filter = { ent, pl },
			mask = MASK_NPCWORLDSTATIC,
			mins = camMins,
			maxs = camMaxs
		} )
	end

	return {
		origin = tr.HitPos,
		angles = dir:Angle(),
		fov = fov
	}

end )

