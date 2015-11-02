module("panel", package.seeall)

-- localized globals
local funcDraw = love.graphics.draw
local funcGetImage = love.graphics.getImage
local funcGetFont = love.graphics.getFont
local funcRemoveValue = table.removeValue

local allPanels = {}

function draw()
	for i, gui in pairs(allPanels) do
		gui.baseUpdate()
	end
	for i, gui in pairs(allPanels) do
		if gui.isVisible() then
			gui.basePaint()
		end
	end
end

function hovering()
	for i, gui in pairs(allPanels) do
		if gui.isVisible() and gui.hovering() and gui.getScrollEnabled() then
			return true
		end
	end
	return false
end

hook(love, "mousereleased", function(x, y, button)
	for i, gui in pairs(allPanels) do
		if gui.isVisible() and gui.hovering() then
			gui.baseClick(button)
		end
	end
end)

function new(initTable)
	local initTable = initTable or {}
	local public = {}

	local parent = nil -- Table code found at the bottem
	local visible = true
	local width, height = 0, 0, 0, 0
	local xpos = initTable["x"] or initTable["pos"][1] or 0
	local ypos = initTable["y"] or initTable["pos"][2] or 0
	if initTable["size"] then
		width = initTable["size"][1] or 0
		height = initTable["size"][2] or 0
	end
	local outline = true
	if initTable["outline"] ~= nil then
		outline = initTable["outline"]
	end
	local color = (initTable["color"] or {r = 255, g = 255, b = 255, a = 255})
	local backGround = true
	if initTable["backGround"] ~= nil then
		backGround = initTable["backGround"]
	end
	local text, textColor, align = (initTable["text"] or  ""), (initTable["textColor"] or {r = 0, g = 0, b = 0, a = 255}), (initTable["align"] or "center")
	local wrap = (initTable["wrap"] or false)
	local texture, textureName, textureColor = (initTable["texture"] or nil), (initTable["textureName"] or ""), (initTable["textureColor"] or {r = nil, g = nil, b = nil, a = nil})
	local textureWidth, textureHeight = (initTable["textureWidth"] or 0), (initTable["textureHeight"] or 0)

	local textureBackGround = false
	if initTable["textureBackGround"] ~= nil then
		textureBackGround = initTable["textureBackGround"]
	end

	local font = (initTable["font"] or nil)
	local progress = -1

	local clickSound = initTable["sound"] or nil
	local scrollEnabled = true

	public.children = {}

	-- Visibility
	function public.setVisible(newVisible)
		for i, gui in pairs(public.children) do
			gui.setVisible(newVisible)
		end
		visible = newVisible
	end
	function public.isVisible()
		return visible
	end

	-- Hovering
	function public.hovering()
		local msX, msY = love.mouse.getX(), love.mouse.getY()
		local x,y = public.getScreenPos()
		return msX >= x and msY >= y and msX <= (x + width) and msY <= (y + height)
	end

	function public.setScrollEnabled(newEnabled)
		scrollEnabled = newEnabled
	end

	function public.getScrollEnabled()
		return scrollEnabled
	end
	-- Parenting
	function public.setParent(newParent)
		if newParent then
			if not parent then
				funcRemoveValue(allPanels, public)
			end
			if newParent == public then return end -- Can't be your own parent
			if newParent and not newParent.getScreenPos then return end -- Need a parent with "getScreenPos"
			parent = newParent
			newParent.children[#newParent.children + 1] = public
		else
			allPanels[#allPanels + 1] = public
		end
	end
	function public.getParent()
		return parent
	end

	-- Size
	function public.setSize(newWidth, newHeight)
		width, height = newWidth, newHeight
	end
	function public.getSize()
		return width, height
	end
	function public.getWide()
		return width
	end
	function public.getTall()
		return height
	end
	function public.getMaxX()
		local x,y = public.getPos()
		return x + width
	end
	function public.getMaxY()
		local x,y = public.getPos()
		return y + height
	end

	-- Position
	function public.setPos(newX, newY)
		xpos, ypos = newX, newY
	end
	function public.getPos()
		return xpos, ypos
	end
	function public.getScreenPos()
		if parent then
			local prntX, prntY = parent.getScreenPos()
			return xpos + prntX, ypos + prntY
		end
		return xpos, ypos
	end

	-- Background
	function public.setBackGround(newBackGround)
		backGround = newBackGround
	end
	function public.hasBackGround()
		return backGround
	end

	-- Colors
	function public.setColor(newR, newG, newB, newA)
		color = {r = newR, g = (newG or newR), b = (newB or newR), a = (newA or 255)}
	end
	function public.setOutlineColor(newR, newG, newB, newA)
		outlineColor = {r = newR, g = (newG or newR), b = (newB or newR), a = (newA or -1)}
	end

	-- Text
	function public.setText(newText)
		text = newText
	end
	function public.setTextColor(newR, newG, newB, newA)
		textColor = {r = newR, g = (newG or newR), b = (newB or newR), a = (newA or 255)}
	end
	function public.setAlign(newAlign)
		align = newAlign
	end

	-- Texturing
	function public.setTexture(newTexture)
		texture = funcGetImage(newTexture)
		textureName = newTexture
		textureWidth, textureHeight = texture:getWidth(), texture:getHeight()
	end
	function public.getTextureWidth()
		return textureWidth
	end
	function public.getTextureHeight()
		return textureHeight
	end
	function public.setTextureColor(newR, newG, newB, newA)
		textureColor = {r = newR, g = (newG or newR), b = (newB or newR), a = (newA or 255)}
	end
	function public.getTextureColor(textureColor)
		return textureColor
	end
	function public.drawTextureBackGround(newTextureBackGround)
		textureBackGround = newTextureBackGround
	end
	function public.drawingTextureBackGround()
		return TextureBackGround
	end

	-- Progress
	function public.setProgress(newProgress)
		progress = newProgress
	end
	function public.getProgress()
		return progress
	end
	--
	function public.setClickSound(newClickSound)
		clickSound = newClickSound
	end
	function public.getClickSound()
		return clickSound
	end
	-- Functionality
	function public.remove()
		for i, gui in pairs(public.children) do
			gui.remove()
		end
		if public.getParent() ~= nil then
			funcRemoveValue(public.getParent().children, public)
		end
		funcRemoveValue(allPanels, public)
	end
	function public.baseUpdate()
		if public.children then
			for k, child in pairs(public.children) do
				child.baseUpdate()
			end
		end
		public.update()
	end
	function public.basePaint()
		local scrX, scrY = xpos, ypos
		if parent then
			scrX, scrY = public.getScreenPos()
		end
		public.paint(scrX, scrY, width, height)

		-- Draw children
		if public.children then
			for k, child in pairs(public.children) do
				love.graphics.setScissor(scrX, scrY, width, height)
				if child.isVisible() then
					child.basePaint()
				end
			end
			love.graphics.setScissor()
		end
	end
	function public.baseClick(button)
		if public.children then
			for k, child in pairs(public.children) do
				if child.isVisible() and child.hovering() then
					child.baseClick(button)
				end
			end
		end
		public.onClick(button)
		if clickSound ~= nil then
			local sound = soundSystem.newSound(clickSound,"static")
			sound:play()
		end
	end
	function public.onClick(button)
	end
	function public.update()
	end
	function public.paint(xpos, ypos, width, height)
		local percent = 1
		if progress >= 0 then
			percent = progress * (1 / 100)
		end

		love.graphics.setColor(color.r, color.g, color.b, color.a)
		if texture then
			if textureBackGround then
				love.graphics.rectangle("fill", xpos, ypos, width * percent, height)
			end
			if textureColor.r ~= nil then
				love.graphics.setColor(textureColor.r, textureColor.g, textureColor.b, textureColor.a)
				funcDraw(texture, xpos, ypos, 0, width / textureWidth, height / textureHeight)
				love.graphics.setColor(color.r, color.g, color.b, color.a)
			else
				funcDraw(texture, xpos, ypos, 0, width / textureWidth, height / textureHeight)
			end
		else
			if backGround then
				love.graphics.rectangle("fill", xpos, ypos, width * percent, height)
			end
		end

		if text ~= "" then
			if font then
				love.graphics.setFont(font)
				ypos = ypos + height/2 - font:getHeight()/2
			end
			love.graphics.setColor(textColor.r, textColor.g, textColor.b, textColor.a)
			if wrap then
				love.graphics.printf(text, xpos, ypos, limit, align)
			else
				love.graphics.printf(text, xpos, ypos, width, align) -- funcGetFont():getHeight() * (1/2)
			end
		end
	end

	if initTable["parent"] ~= nil then
		public.setParent(initTable["parent"])
	else
		allPanels[#allPanels + 1] = public
	end

	return public
end
