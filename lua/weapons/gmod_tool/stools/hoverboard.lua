
// basic
TOOL.Category = "Robotboy655"
TOOL.Name = "#tool.hoverboard.name"

-- TO ADD NEW HOVERBOARDS, CHECK OUT THE AUTORUN FILE

AddCSLuaFile( "vgui/hoverboard_gui.lua" )

cleanup.Register( "hoverboards" )

for _, hbt in pairs( HoverboardTypes ) do

	list.Set( "HoverboardModels", hbt[ 'model' ], {} )
	util.PrecacheModel( hbt[ 'model' ] )

	if ( SERVER && GetConVarNumber( "rb655_force_downloads" ) > 0 ) then

		resource.AddFile( hbt[ 'model' ] )

		if ( hbt[ 'files' ] ) then

			for __, f in pairs( hbt[ 'files' ] ) do

				resource.AddFile( f ) // send other files

			end

		end

	end

end

TOOL.ClientConVar[ 'model' ] = "models/UT3/hoverboard.mdl"
TOOL.ClientConVar[ 'lights' ] = 0
TOOL.ClientConVar[ 'mousecontrol' ] = 1
TOOL.ClientConVar[ 'boostshake' ] = 1
TOOL.ClientConVar[ 'height' ] = 72
TOOL.ClientConVar[ 'viewdist' ] = 128
TOOL.ClientConVar[ 'trail_size' ] = 5
TOOL.ClientConVar[ 'trail_r' ] = 128
TOOL.ClientConVar[ 'trail_g' ] = 128
TOOL.ClientConVar[ 'trail_b' ] = 255
TOOL.ClientConVar[ 'boost_r' ] = 128
TOOL.ClientConVar[ 'boost_g' ] = 255
TOOL.ClientConVar[ 'boost_b' ] = 128
TOOL.ClientConVar[ 'recharge_r' ] = 255
TOOL.ClientConVar[ 'recharge_g' ] = 128
TOOL.ClientConVar[ 'recharge_b' ] = 128
TOOL.ClientConVar[ 'speed' ] = 10
TOOL.ClientConVar[ 'jump' ] = 10
TOOL.ClientConVar[ 'turn' ] = 10
TOOL.ClientConVar[ 'flip' ] = 10
TOOL.ClientConVar[ 'twist' ] = 5

function TOOL:LeftClick( trace )

	local result, hoverboard = self:CreateBoard( trace )
	return result

end

function TOOL:RightClick( trace )

	local result, hoverboard = self:CreateBoard( trace )

	if ( CLIENT ) then return result end // client result

	if ( IsValid( hoverboard ) ) then // validate board

		local pl = self:GetOwner() // owner
		local dist = ( hoverboard:GetPos() - pl:GetPos() ):Length() // check distance

		if ( dist <= 512 ) then // make sure its relatively close?

			timer.Simple( 0.25, function() // had to delay it to avoid errors

				if ( IsValid( hoverboard ) && IsValid( pl ) ) then hoverboard:SetDriver( pl ) end

			end )

		end

	end

	return result

end

function TOOL:CreateBoard( trace )
	if ( CLIENT ) then return true end

	local pl = self:GetOwner()
	if ( GetConVarNumber( "sv_hoverboard_adminonly" ) > 0 && !( pl:IsAdmin() || pl:IsSuperAdmin() ) ) then return false end

	local model = self:GetClientInfo( "model" )
	local mcontrol = self:GetClientNumber( "mousecontrol" )
	local shake = self:GetClientNumber( "boostshake" )
	local trailsize = math.Clamp( self:GetClientNumber( "trail_size" ), 0, 10 )
	local height = math.Clamp( self:GetClientNumber( "height" ), 36, 100 )
	local viewdist = math.Clamp( self:GetClientNumber( "viewdist" ), 64, 256 )
	local trail = Vector( self:GetClientNumber( "trail_r" ), self:GetClientNumber( "trail_g" ), self:GetClientNumber( "trail_b" ) )
	local boost = Vector( self:GetClientNumber( "boost_r" ), self:GetClientNumber( "boost_g" ), self:GetClientNumber( "boost_b" ) )
	local recharge = Vector( self:GetClientNumber( "recharge_r" ), self:GetClientNumber( "recharge_g" ), self:GetClientNumber( "recharge_b" ) )

	local attributes = {
		speed = math.Clamp( self:GetClientNumber( "speed" ), 0, 15 ),
		jump = math.Clamp( self:GetClientNumber( "jump" ), 0, 15 ),
		turn = math.Clamp( self:GetClientNumber( "turn" ), 0, 15 ),
		flip = math.Clamp( self:GetClientNumber( "flip" ), 0, 15 ),
		twist = math.Clamp( self:GetClientNumber( "twist" ), 0, 15 )
	}

	local ang = pl:GetAngles()
	ang.p = 0
	ang.y = ang.y + 180

	local pos = trace.HitPos + trace.HitNormal * 32

	local hoverboard = MakeHoverboard( pl, model, ang, pos, mcontrol, shake, height, viewdist, trailsize, trail, boost, recharge, attributes )
	if ( !IsValid( hoverboard ) ) then return false end

	undo.Create( "Hoverboard" )
		undo.AddEntity( hoverboard )
		undo.SetPlayer( pl )
	undo.Finish()

	return true, hoverboard

end

function TOOL:Reload( trace )
end

function TOOL:Think()
end

if ( SERVER ) then

	function MakeHoverboard( pl, model, ang, pos, mcontrol, shake, height, viewdist, trailsize, trail, boost, recharge, attributes )

		if ( IsValid( pl ) && !pl:CheckLimit( "hoverboards" ) ) then return false end

		local hoverboard = ents.Create( "modulus_hoverboard" )

		if ( !IsValid( hoverboard ) ) then return false end

		local boardinfo

		for _, board in pairs( HoverboardTypes ) do

			if ( board[ 'model' ]:lower() == model:lower() ) then

				boardinfo = board
				break

			end

		end

		if ( !boardinfo ) then return false end

		util.PrecacheModel( model )

		hoverboard:SetModel( model )
		hoverboard:SetAngles( ang )
		hoverboard:SetPos( pos )

		hoverboard:SetBoardRotation( 0 )

		if ( boardinfo[ "rotation" ] ) then

			local rot = tonumber( boardinfo[ "rotation" ] )

			hoverboard:SetBoardRotation( tonumber( boardinfo[ "rotation" ] ) )

			ang.y = ang.y - rot
			hoverboard:SetAngles( ang )

		end

		hoverboard:Spawn()
		hoverboard:Activate()

		hoverboard:SetAvatarPosition( Vector( 0, 0, 0 ) )

		if ( boardinfo[ 'driver' ] ) then

			hoverboard:SetAvatarPosition( boardinfo[ 'driver' ] )

		end

		for k, v in pairs( boardinfo ) do

			if ( k:sub( 1, 7 ):lower() == "effect_" && type( boardinfo[ k ] == "table" ) ) then

				local effect = boardinfo[ k ]

				local normal
				if ( effect[ 'normal' ] ) then normal = effect[ 'normal' ] end

				hoverboard:AddEffect( effect[ 'effect' ] or "trail", effect[ 'position' ], normal, effect[ 'scale' ] or 1 )

			end

		end

		hoverboard:SetControls( math.Clamp( tonumber( mcontrol ), 0, 1 ) ) // controls
		hoverboard:SetBoostShake( math.Clamp( tonumber( shake ), 0, 1 ) ) // boost shake
		hoverboard:SetHoverHeight( math.Clamp( tonumber( height ), 36, 100 ) ) // hover height
		hoverboard:SetViewDistance( math.Clamp( tonumber( viewdist ), 64, 256 ) ) // view distance
		hoverboard:SetSpring( 0.21 * ( ( 72 / height ) * ( 72 / height ) ) ) // spring

		trailsize = math.Clamp( trailsize, 0, 10 ) * 0.3
		hoverboard:SetTrailScale( trailsize )
		hoverboard:SetTrailColor( trail )
		hoverboard:SetTrailBoostColor( boost )
		hoverboard:SetTrailRechargeColor( recharge )

		//local count = 0
		//local points = GetConVarNumber( "sv_hoverboard_points" )

		for k, v in pairs( attributes ) do

			//local remaining = points - count

			//v = math.Clamp( v, 0, math.min( 16, remaining ) )

			v = math.Clamp( v, 0, 16 )

			//attributes[ k ] = v

			//count = count + v

		end

		/*for k, v in pairs( boardinfo[ 'bonus' ] or {} ) do

			if ( attributes[ k ] ) then

				attributes[ k ] = attributes[ k ] + tonumber( v )

			end

		end*/

		local speed = ( attributes[ 'speed' ] * 0.1 ) * 20
		hoverboard:SetSpeed( speed )
		local jump = ( attributes[ 'jump' ] * 0.1 ) * 250 -- It seems to me that this should be 2500
		hoverboard:SetJumpPower( jump )
		local turn = ( attributes[ 'turn' ] * 0.1 ) * 25
		hoverboard:SetTurnSpeed( turn )
		local flip = ( attributes[ 'flip' ] * 0.1 ) * 25
		hoverboard:SetPitchSpeed( flip )
		local twist = ( attributes[ 'twist' ] * 0.1 ) * 25
		hoverboard:SetYawSpeed( twist )
		local roll = ( ( flip + twist * 0.5 ) / 50 ) * 22
		hoverboard:SetRollSpeed( roll )

		DoPropSpawnedEffect( hoverboard )

		if ( IsValid( pl ) ) then
			pl:AddCount( "hoverboards", hoverboard )
			pl:AddCleanup( "hoverboards", hoverboard )
			hoverboard.Creator = pl:UniqueID()
		end

		return hoverboard

	end

	return
end

language.Add( "tool.hoverboard.name", "Hoverboards" )
language.Add( "tool.hoverboard.desc", "Spawn customized hoverboards" )
language.Add( "tool.hoverboard.0", "Left click to spawn a hoverboard. Right click to spawn a hoverboard & mount onto it." )

language.Add( "tool.hoverboard.lights", "Trail lights" )
language.Add( "tool.hoverboard.lights.help", "The next commands are accessible to the server hoster only ON A LISTEN SERVER ONLY!" )

language.Add( "Undone_hoverboard", "Undone Hoverboard" )
language.Add( "SBoxLimit_hoverboards", "You've reached the Hoverboard limit!" )

local hbpanel = vgui.RegisterFile( "vgui/hoverboard_gui.lua" )

function TOOL.BuildCPanel( cp )

	//cp:AddControl( "PropSelect", { Label = "Hoverboard Model", Height = 3, ConVar = "hoverboard_model", Models = list.Get( "HoverboardModels" ) } )

	local panel = vgui.CreateFromTable( hbpanel )
	panel:PopulateBoards( HoverboardTypes )
	panel:PerformLayout( )
	cp:AddPanel( panel )

	cp:AddControl( "Color", { Label = "Trail Color", Red = "hoverboard_trail_r", Green = "hoverboard_trail_g", Blue = "hoverboard_trail_b", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1" } )
	cp:AddControl( "Color", { Label = "Boost Color", Red = "hoverboard_boost_r", Green = "hoverboard_boost_g", Blue = "hoverboard_boost_b", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1" } )
	cp:AddControl( "Color", { Label = "Recharge Color", Red = "hoverboard_recharge_r", Green = "hoverboard_recharge_g", Blue = "hoverboard_recharge_b", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1" } )

	cp:AddControl( "Slider", { Label = "Trail Size", Min = 0, Max = 10, Command = "hoverboard_trail_size" } )
	cp:AddControl( "Slider", { Label = "Hover Height", Min = 36, Max = 100, Command = "hoverboard_height" } )
	cp:AddControl( "Slider", { Label = "View Distance", Min = 64, Max = 256, Command = "hoverboard_viewdist" } )

	cp:AddControl( "Checkbox", { Label = "Mouse Control", Command = "hoverboard_mousecontrol" } )
	cp:AddControl( "Checkbox", { Label = "Boost Shake", Command = "hoverboard_boostshake" } )
	cp:AddControl( "Checkbox", { Label = "#tool.hoverboard.lights", Command = "hoverboard_lights", Help = true } )

	cp:AddControl( "Checkbox", { Label = "ADMIN: Can Fall From Hoverboard?", Command = "sv_hoverboard_canfall" } )
	cp:AddControl( "Checkbox", { Label = "ADMIN: Can Share?", Command = "sv_hoverboard_canshare" } )
	cp:AddControl( "Checkbox", { Label = "ADMIN: Can Steal?", Command = "sv_hoverboard_cansteal" } )
	cp:AddControl( "Checkbox", { Label = "ADMIN: Admin Only?", Command = "sv_hoverboard_adminonly" } )
	cp:AddControl( "Slider", { Label = "ADMIN: Max Hoverboards Per Player", Min = 1, Max = 10, Command = "sbox_maxhoverboards" } )
	//cp:AddControl( "Slider", { Label = "ADMIN: Max Points", Min = 5, Max = 80, Command = "sv_hoverboard_points" } )

end
