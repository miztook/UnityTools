
Rect = 
{	
	x = 0,
	y = 0,		
	width = 0,
	height = 0,

	class = "Rect",
}

function Rect.New(x, y, width, height)
	local v = {}
	setmetatable(v, Rect)
	v.x = x or 0
	v.y = y or 0	
	v.width = width or 0
	v.height = height or 0
	return v
end

function Rect:Get()
	return self.x, self.y, self.width, self.height
end


