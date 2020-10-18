
AddCSLuaFile()

if ( SERVER ) then

	CreateConVar( "sbox_maxhoverboards", 2, { FCVAR_NOTIFY, FCVAR_ARCHIVE } )
	CreateConVar( "sv_hoverboard_adminonly", 0, { FCVAR_NOTIFY, FCVAR_ARCHIVE } )
	CreateConVar( "sv_hoverboard_cansteal", 0, { FCVAR_NOTIFY, FCVAR_ARCHIVE } )
	CreateConVar( "sv_hoverboard_canshare", 1, { FCVAR_NOTIFY, FCVAR_ARCHIVE } )
	CreateConVar( "sv_hoverboard_canfall", 1, { FCVAR_NOTIFY, FCVAR_ARCHIVE } )
	--CreateConVar( "sv_hoverboard_points", "45", { FCVAR_NOTIFY, FCVAR_ARCHIVE } )

	/*util.AddNetworkString("rb655_hoverpoints")
	timer.Create( "HoverPointsThink", 5, 0, function()
		net.Start("rb655_hoverpoints")
			net.WriteString( GetConVarString( "sv_hoverboard_points" ) )
		net.Broadcast()
	end )*/

	--CreateConVar( "rb655_force_downloads", "0", FCVAR_ARCHIVE )

	/*if ( GetConVarNumber( "rb655_force_downloads" ) > 0 ) then
		resource.AddFile( "materials/modulus_hoverboard/glow.vmt" )
		resource.AddFile( "materials/modulus_hoverboard/trail.vmt" )
		resource.AddFile( "materials/modulus_hoverboard/deathicon.vmt" )
		resource.AddFile( "materials/modulus_hoverboard/deathicon.vtf" )
	end*/

	resource.AddWorkshop( 150455514 )
else
	CreateConVar( "cl_hoverboard_developer", "0", FCVAR_CHEAT )

	language.Add( "modulus_hoverboard", "Hoverboard" )
	language.Add( "modulus_hoverboard_hull", "Hoverboard" )
	language.Add( "modulus_hoverboard_avatar", "Hoverboard" )

	killicon.Add( "modulus_hoverboard", "modulus_hoverboard/deathicon", Color( 255, 80, 0, 255 ) )
	killicon.AddAlias( "modulus_hoverboard_hull", "modulus_hoverboard" )
	killicon.AddAlias( "modulus_hoverboard_avatar", "modulus_hoverboard" )
end

/* ------------------------------------------------
	Hoverboard Types
------------------------------------------------ */

HoverboardTypes = {}

table.insert( HoverboardTypes, {
	bonus = {
		jump = 2,
		speed = 1,
		turn = 1,
	},
	model = "models/dav0r/hoverboard/hoverboard.mdl",
	name = "Hackjob",
	rotation = 90,
	driver = Vector( 0, -6, 3 ),
	effect_1 = {
		effect = "trail",
		position = Vector( -4, 16.8, 2 )
	},
	effect_2 = {
		effect = "trail",
		position = Vector(4, 16.8, 2)
	},
	effect_3 = {
		effect = "heatwave",
		position = Vector(0, 5, 0),
		normal = Vector(0, 0, -1),
		scale = 1
	},
	effect_4 = {
		effect = "heatwave",
		position = Vector( 0, -21, 0 ),
		normal = Vector( 0, 0, -1 ),
		scale = 1
	},
	files = {
		"materials/models/hoverboard/boardmap.vmt",
		"materials/models/hoverboard/boardmap.vtf",
		"materials/models/hoverboard/boardnormal.vtf",
		"materials/models/hoverboard/boardtransparency.vmt",
		"materials/models/hoverboard/boardtransparency.vtf"
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		jump = 2,
		flip = 2
	},
	model = "models/ut3/hoverboard.mdl",
	name = "Unreal",
	rotation = 0,
	driver = Vector( 0, 0, 5 ),
	effect_1 = {
		effect = "trail",
		position = Vector( -10.9664, -3.6816,  -6.7901 )
	},
	effect_2 = {
		effect = "trail",
		position = Vector( -11.2077, 4.9971, -6.6772 )
	},
	files = {
		"materials/ut3/hoverboard.vmt",
		"materials/ut3/hoverboard.vtf",
		"materials/ut3/hoverboard_mask.vtf",
		"materials/ut3/hoverboard_normal.vtf"
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		turn = 2,
		speed = 2
	},
	model = "models/jaanus/scopesboard.mdl",
	name = "Huvaboard",
	rotation = 90,
	effect_1 = {
		effect = "plasma_thruster_middle",
		position = Vector( -5.2707, -14.5196, 0 ),
		normal = Vector( 0, 0, -1 )
	},
	effect_2 = {
		effect = "plasma_thruster_middle",
		position = Vector( 5.2707, -14.5196, 0 ),
		normal = Vector( 0, 0, -1 )
	},
	effect_3 = {
		effect = "plasma_thruster_middle",
		position = Vector( 5.2707, 14.5196, 0 ),
		normal = Vector( 0, 0, -1 )
	},
	effect_4 = {
		effect = "plasma_thruster_middle",
		position = Vector( -5.2707, 14.5196, 0 ),
		normal = Vector( 0, 0, -1 )
	},
	effect_5 = {
		effect = "trail",
		position = Vector( -0.2088, 23.0561, -2.6297 ),
	},
	files = {
		"materials/Jaanus/huvaburd.vmt",
		"materials/Jaanus/huvaburd.vtf",
		"materials/Jaanus/enginefuck.vtf",
		"materials/Jaanus/enginefuck.vmt"
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		turn = 1,
		speed = 3
	},
	model = "models/jaanus/truehoverboard_1.mdl",
	name = "Mr. Plank",
	rotation = 90,
	effect_1 = {
		effect = "heatwave",
		position = Vector( 0.2036, 0.3881, -3.2154 ),
		normal = Vector( 0, 0, -1 ),
		scale = 1
	},
	effect_2 = {
		effect = "heatwave",
		position = Vector( 0.2036, 26.1925, -3.2154 ),
		normal = Vector( 0, 0, -1 ),
		scale = 1
	},
	effect_3 = {
		effect = "heatwave",
		position = Vector( 0.1847, -26.8710, -2.8477 ),
		normal = Vector( 0, 0, -1 ),
		scale = 1
	},
	effect_4 = {
		effect = "trail",
		position = Vector( 5.2859, 40.6489, -0.2452 ),
	},
	effect_5 = {
		effect = "trail",
		position = Vector( -5.2859, 40.6489, -0.24527 ),
	},
	files = {
		"materials/Jaanus/bawrd.vmt",
		"materials/Jaanus/bawrd.vtf",
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		twist = 1,
		speed = 3
	},
	model = "models/jaanus/truehoverboard_2.mdl",
	name = "Mr. Plank II",
	rotation = 90,
	effect_1 = {
		effect = "trail",
		position = Vector( 5.2859, 40.6489, -0.2452 ),
	},
	effect_2 = {
		effect = "trail",
		position = Vector( -5.2859, 40.6489, -0.2452 ),
	},
	files = {
		"materials/jaanus/bawrd.vmt",
		"materials/jaanus/bawrd.vtf",
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		twist = 2,
		flip = 2
	},
	model = "models/jaanus/stuntboard.mdl",
	name = "Stuntboard",
	rotation = 90,
	effect_1 = {
		effect = "plasma_thruster_middle",
		position = Vector( 3.4516, 0.0278, 0 ),
		normal = Vector( 0, 0, -1 ),
	},
	effect_2 = {
		effect = "plasma_thruster_middle",
		position = Vector( -3.4516, 0.0278, 0 ),
		normal = Vector( 0, 0, -1 ),
	},
	effect_3 = {
		effect = "plasma_thruster_middle",
		position = Vector( -2.4516, 29.2273, 0 ),
		normal = Vector( 0, 0.3, -0.91 ),
	},
	effect_4 = {
		effect = "plasma_thruster_middle",
		position = Vector( 2.4516, 29.2273, 0 ),
		normal = Vector( 0, 0.3, -0.91 ),
	},
	effect_5 = {
		effect = "plasma_thruster_middle",
		position = Vector( -2.4516, -29.2273, 0 ),
		normal = Vector( 0, -0.3, -0.91 ),
	},
	effect_6 = {
		effect = "plasma_thruster_middle",
		position = Vector( 2.4516, -29.2273, 0 ),
		normal = Vector( 0, -0.3, -0.91 ),
	},
	effect_7 = {
		effect = "trail",
		position = Vector( -0.1127, 31.5908, 0.9696 )
	},
	files = {
		"materials/jaanus/stuntboard.vmt",
		"materials/jaanus/stuntboard.vtf",
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		twist = 2,
		flip = 2
	},
	model = "models/squint_hoverboard/hoverboard.mdl",
	name = "Squint Hoverboard",
	rotation = 90,
	effect_1 = {
		effect = "heatwave",
		position = Vector( 0, 25, -5 ),
		normal = Vector( 0, 0, -1 ),
		scale = 1
	},
	effect_2 = {
		effect = "heatwave",
		position = Vector( 0, -25, -5 ),
		normal = Vector( 0, 0, -1 ),
		scale = 1
	},
	files = {
		"materials/models/squint_hoverboard/squint_hoverboard.vmt",
		"materials/models/squint_hoverboard/squint_hoverboard.vtf",
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		twist = 6,
		flip = 6,
		speed = 6,
		jump = 6,
		turn = 6
	},
	model = "models/squint_hoverboard/hotrod.mdl",
	name = "HotRod",
	rotation = 90,
	driver = Vector( 1.5, 0, -1.5 ),
	effect_1 = {
		effect = "plasma_thruster_middle",
		position = Vector( 11, 22, 0 ),
		normal = Vector( 0, 1.85, 0.90 ),
	},
	effect_2 = {
		effect = "plasma_thruster_middle",
		position = Vector( -11, 22, 0 ),
		normal = Vector( 0, 1.85, 0.90 ),
	},
	effect_3 = {
		effect = "plasma_thruster_middle",
		position = Vector( 11, 27.5, 0 ),
		normal = Vector( 0, 1.85, 0.90 ),
	},
	effect_4 = {
		effect = "plasma_thruster_middle",
		position = Vector( -11, 27.5, 0 ),
		normal = Vector( 0, 1.85, 0.90 ),
	},
	effect_5 = {
		effect = "plasma_thruster_middle",
		position = Vector( 11, 33, 0 ),
		normal = Vector( 0, 1.85, 0.90 ),
	},
	effect_6 = {
		effect = "plasma_thruster_middle",
		position = Vector( -11, 33, 0 ),
		normal = Vector( 0, 1.85, 0.90 ),
	},
	effect_7 = {
		effect = "trail",
		position = Vector( 8.5, 40, -2.5 ),
	},
	effect_8 = {
		effect = "trail",
		position = Vector( -8.5, 40, -2.5 ),
	},
	files = {
		"materials/models/squint_hoverboard/hotrod/hotrod.vmt",
		"materials/models/squint_hoverboard/hotrod/hotrod.vtf",
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		speed = 3,
		turn = 2
	},
	model = "models/squint_hoverboard/asltd.mdl",
	name = "Aperture Science Levitantional Transportation Device",
	rotation = 180,
	driver = Vector( -3, 0, 3 ),
	effect_1 = {
		effect = "plasma_thruster_middle",
		position = Vector( -30, 0, 0 ),
		normal = Vector( -15, 0, 1 ),
		scale = 1,
	},
	effect_2 = {
		effect = "heatwave",
		position = Vector( -18, 0, -6 ),
		normal = Vector( 0, 0, -1 ),
	},
	effect_3 = {
		effect = "heatwave",
		position = Vector( 18, 0, -6 ),
		normal = Vector( 0, 0, -1 ),
	},
	effect_4 = {
		effect = "trail",
		position = Vector( -30, 0, 0 ),
	},
	files = {
		"materials/models/squint_hoverboard/asltd/asltd.vmt",
		"materials/models/squint_hoverboard/asltd/asltd.vtf",
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		flip = 1,
		twist = 3
	},
	model = "models/cloudstrifexiii/boards/trickhoverboard.mdl",
	name = "Cloud's Trickboard",
	rotation = 90,
	driver = Vector( 0, 2, 1 ),
	files = {
		"materials/models/cloudstrifexiii/boards/trickboard.vmt",
		"materials/models/cloudstrifexiii/boards/trickboard.vtf",
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		speed = 1,
		twist = 1,
		turn = 1,
		jump = 1,
	},
	model = "models/cloudstrifexiii/boards/regularhoverboard.mdl",
	name = "Cloud's Normal Board",
	rotation = 90,
	driver = Vector( 0, 2, 1.5 ),
	files = {
		"materials/models/cloudstrifexiii/boards/normalboard.vmt",
		"materials/models/cloudstrifexiii/boards/normalboard.vtf",
	}
} )

table.insert( HoverboardTypes, {
	bonus = {
		speed = 4
	},
	model = "models/cloudstrifexiii/boards/longhoverboard.mdl",
	name = "Cloud's Longboard",
	rotation = 90,
	driver = Vector( 0, 2, 1 ),
	files = {
		"materials/models/cloudstrifexiii/boards/longboard.vmt",
		"materials/models/cloudstrifexiii/boards/longboard.vtf",
	}
} )
