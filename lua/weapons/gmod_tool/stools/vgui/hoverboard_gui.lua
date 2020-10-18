
function PANEL:Init( )

	--self.AttributePoints = 5
	self.Attributes = {}

	self.BoardSelect = vgui.Create( "PropSelect", self )
	self.BoardSelect:SetConVar( "hoverboard_model" )
	self.BoardSelect.Label:SetText( "Select Model" )

	/*self.PointsText = vgui.Create( "DLabel", self )
	self.PointsText:SetText( "Attribute Points: 0" )
	self.PointsText:SetDark( true )
	self.PointsText:SizeToContents()*/

	self:AddAttribute( "Speed" )
	self:AddAttribute( "Jump" )
	self:AddAttribute( "Turn" )
	self:AddAttribute( "Flip" )
	self:AddAttribute( "Twist" )

end

function PANEL:PerformLayout( )

	local vspacing = 10
	local ypos = 0

	self.BoardSelect:SetPos( 0, ypos )
	self.BoardSelect:SetSize( self:GetWide(), 165 )
	ypos = self.BoardSelect.Y + self.BoardSelect:GetTall() + vspacing

	/*self.PointsText:SetPos( 0, ypos )
	ypos = self.PointsText.Y + self.PointsText:GetTall() + vspacing*/

	for _, panel in pairs( self.Attributes ) do

		panel:SetPos( 0, ypos )
		panel:SetSize( self:GetWide(), panel:GetTall() )
		ypos = panel.Y + panel:GetTall() + vspacing

	end

	self:SetHeight( ypos )

	self:UpdatePoints()

end

/*local HoverPoints = 5
net.Receive( "rb655_hoverpoints", function()
	HoverPoints = tonumber( net.ReadString() )
end )*/

function PANEL:Think()

	/*local points = HoverPoints

	if ( points != self.AttributePoints ) then

		points = math.max( tonumber( points ), 10 )

		for name, panel in pairs( self.Attributes ) do

			panel:SetValue( 0 )
			panel:ValueChanged( 0 )
			panel:InvalidateLayout()

		end

		self.AttributePoints = points

		self:UpdatePoints()

	end*/

	if ( self.HoverboardTable ) then

		local selected = GetConVarString( self.BoardSelect:ConVar() )

		if ( selected != self.LastSelectedBoard ) then

			self.LastSelectedBoard = selected

			for name, panel in pairs( self.Attributes ) do

				panel:SetText( name )
				panel.Label:SetTextColor( panel.OldFontColor )

			end

			/*for _, board in pairs( self.HoverboardTable ) do

				if ( selected:lower() == board[ "model" ]:lower() ) then

					for k, v in pairs( board[ "bonus" ] ) do

						for name, panel in pairs( self.Attributes ) do

							if ( panel.Attribute == k:lower() ) then

								panel:SetText( ("%s +%d"):format( name, tonumber( v ) ) )
								panel.Label:SetTextColor( Color( 0, 200, 0, 255 ) )

							end

						end

					end

					break

				end

			end*/

		end

	end

end

function PANEL:PopulateBoards( tbl )

	for _, board in pairs( tbl ) do

		self.BoardSelect:AddModel( board[ "model" ] )

		self.BoardSelect.Controls[ #self.BoardSelect.Controls ]:SetTooltip( board[ "name" ] or "Unknown" )

	end

	self.HoverboardTable = tbl

end

function PANEL:GetUsedPoints( ignore )

	local count = 0

	/*for _, panel in pairs( self.Attributes ) do

		if ( panel != ignore ) then

			count = count + panel:GetValue()

		end

	end*/

	return count

end

function PANEL:UpdatePoints( )

	/*self.PointsText:SetText( ( "Attribute Points: %d/%s" ):format( self.AttributePoints - self:GetUsedPoints(), self.AttributePoints ) )
	self.PointsText:SizeToContents()*/

end

function PANEL:AddAttribute( name )

	local panel = vgui.Create( "DNumSlider", self )
	panel:SetText( name )
	panel:SetMin( 0 )
	panel:SetMax( 16 )

	panel:SetDark( true )
	panel:SetDecimals( 0 )
	panel:SetConVar( ( "hoverboard_%s" ):format( name:lower() ) )
	panel.Attribute = name:lower()
	panel.OnValueChanged = function( slider, val )


		val = math.Clamp( tonumber( val ), 0, 16 )
		slider:SetValue( val )

		/*local count = self:GetUsedPoints( slider )

		if ( count + val > self.AttributePoints ) then

			val = self.AttributePoints - count

			val = math.Clamp( tonumber( val ), 0, 16 )
			slider:SetValue( val )
			slider:ValueChanged( val )
			slider:InvalidateLayout()

		end

		self:UpdatePoints()*/

	end

	panel.OldFontColor = panel.Label:GetTextColor()

	self.Attributes[ name ] = panel

end
