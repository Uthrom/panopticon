local Events = {}

function PointWithinShape(shape, tx, ty)
	if #shape == 0 then 
		return false
	elseif #shape == 1 then 
		return shape[1].x == tx and shape[1].y == ty
	elseif #shape == 2 then 
		return PointWithinLine(shape, tx, ty)
	else 
		return CrossingsMultiplyTest(shape, tx, ty)
	end
end
 
function BoundingBox(box, tx, ty)
	return	(box[2].x >= tx and box[2].y >= ty)
		and (box[1].x <= tx and box[1].y <= ty)
		or  (box[1].x >= tx and box[2].y >= ty)
		and (box[2].x <= tx and box[1].y <= ty)
end
 
function colinear(line, x, y, e)
	e = e or 0.1
	m = (line[2].y - line[1].y) / (line[2].x - line[1].x)
	local function f(x) return line[1].y + m*(x - line[1].x) end
	return math.abs(y - f(x)) <= e
end
 
function PointWithinLine(line, tx, ty, e)
	e = e or 0.66
	if BoundingBox(line, tx, ty) then
		return colinear(line, tx, ty, e)
	else
		return false
	end
end
 
-------------------------------------------------------------------------
-- The following function is based off code from
-- [ http://erich.realtimerendering.com/ptinpoly/ ]
--
--[[
 ======= Crossings Multiply algorithm ===================================
 * This version is usually somewhat faster than the original published in
 * Graphics Gems IV; by turning the division for testing the X axis crossing
 * into a tricky multiplication test this part of the test became faster,
 * which had the additional effect of making the test for "both to left or
 * both to right" a bit slower for triangles than simply computing the
 * intersection each time.  The main increase is in triangle testing speed,
 * which was about 15% faster; all other polygon complexities were pretty much
 * the same as before.  On machines where division is very expensive (not the
 * case on the HP 9000 series on which I tested) this test should be much
 * faster overall than the old code.  Your mileage may (in fact, will) vary,
 * depending on the machine and the test data, but in general I believe this
 * code is both shorter and faster.  This test was inspired by unpublished
 * Graphics Gems submitted by Joseph Samosky and Mark Haigh-Hutchinson.
 * Related work by Samosky is in:
 *
 * Samosky, Joseph, "SectionView: A system for interactively specifying and
 * visualizing sections through three-dimensional medical image data",
 * M.S. Thesis, Department of Electrical Engineering and Computer Science,
 * Massachusetts Institute of Technology, 1993.
 *
 --]]
 
--[[ Shoot a test ray along +X axis.  The strategy is to compare vertex Y values
 * to the testing point's Y and quickly discard edges which are entirely to one
 * side of the test ray.  Note that CONVEX and WINDING code can be added as
 * for the CrossingsTest() code; it is left out here for clarity.
 *
 * Input 2D polygon _pgon_ with _numverts_ number of vertices and test point
 * _point_, returns 1 if inside, 0 if outside.
 --]]
function CrossingsMultiplyTest(pgon, tx, ty)
	local i, yflag0, yflag1, inside_flag
	local vtx0, vtx1
 
	local numverts = #pgon
 
	vtx0 = pgon[numverts]
	vtx1 = pgon[1]
 
	-- get test bit for above/below X axis
	yflag0 = ( vtx0.y >= ty )
	inside_flag = false
 
	for i=2,numverts+1 do
		yflag1 = ( vtx1.y >= ty )
 
		--[[ Check if endpoints straddle (are on opposite sides) of X axis
		 * (i.e. the Y's differ); if so, +X ray could intersect this edge.
		 * The old test also checked whether the endpoints are both to the
		 * right or to the left of the test point.  However, given the faster
		 * intersection point computation used below, this test was found to
		 * be a break-even proposition for most polygons and a loser for
		 * triangles (where 50% or more of the edges which survive this test
		 * will cross quadrants and so have to have the X intersection computed
		 * anyway).  I credit Joseph Samosky with inspiring me to try dropping
		 * the "both left or both right" part of my code.
		 --]]
		if ( yflag0 ~= yflag1 ) then
			--[[ Check intersection of pgon segment with +X ray.
			 * Note if >= point's X; if so, the ray hits it.
			 * The division operation is avoided for the ">=" test by checking
			 * the sign of the first vertex wrto the test point; idea inspired
			 * by Joseph Samosky's and Mark Haigh-Hutchinson's different
			 * polygon inclusion tests.
			 --]]
			if ( ((vtx1.y - ty) * (vtx0.x - vtx1.x) >= (vtx1.x - tx) * (vtx0.y - vtx1.y)) == yflag1 ) then
				inside_flag =  not inside_flag
			end
		end
 
		-- Move to the next pair of vertices, retaining info as possible.
		yflag0  = yflag1
		vtx0    = vtx1
		vtx1    = pgon[i]
	end
 
	return  inside_flag
end
 
function GetIntersect( points )
	local g1 = points[1].x
	local h1 = points[1].y
 
	local g2 = points[2].x
	local h2 = points[2].y
 
	local i1 = points[3].x
	local j1 = points[3].y
 
	local i2 = points[4].x
	local j2 = points[4].y
 
	local xk = 0
	local yk = 0
 
	if checkIntersect({x=g1, y=h1}, {x=g2, y=h2}, {x=i1, y=j1}, {x=i2, y=j2}) then
		local a = h2-h1
		local b = (g2-g1)
		local v = ((h2-h1)*g1) - ((g2-g1)*h1)
 
		local d = i2-i1
		local c = (j2-j1)
		local w = ((j2-j1)*i1) - ((i2-i1)*j1)
 
		xk = (1/((a*d)-(b*c))) * ((d*v)-(b*w))
		yk = (-1/((a*d)-(b*c))) * ((a*w)-(c*v))
	end
	return xk, yk
end

local function _addRadar(list, radar)
  local found = False
  for k,v in ipairs(global.Mod.RadarCoords) do
    if v == radar.position then
      found = True
    end
  end
  if not found then
    if radar.position.x < global.Mod.West then
      global.Mod.West = radar.position.x
    end
    if radar.position.x > global.Mod.East then
      global.Mod.East = radar.position.x
    end
    if radar.position.y < global.Mod.North then
      global.Mod.North = radar.position.y
    end
    if radar.position.y > global.Mod.South then
      global.Mod.South = radar.position.y
    end
    log(string.format("Added: %d, %d", radar.position.x, radar.position.y))
    log(string.format("New N/S/E/W Max Coords: %d, %d, %d, %d", global.Mod.North, global.Mod.South, global.Mod.East, global.Mod.West))
	table.insert(list, radar.position)
	Events._findBaseCandidates()
  end
end

local function _findBaseCandidates()
	local surf = game.surfaces.nauvis
	global.Mod.BaseCandidates = {}

	for chunk in surf.get_chunks() do
	  local left, top = (chunk.x * 32) + 16, (chunk.y * 32) + 16
	  if (top > global.Mod.North) and (top < global.Mod.South) and 
		 (left > global.Mod.West) and (left < global.Mod.East) then
		if PointWithinShape(global.Mod.RadarCoords, left, top) then
			table.insert(global.Mod.BaseCandidates, {x = left, y = top })
		  nChunks = nChunks + 1
		end
	  end
	end

function Events.findall_radars()
  global.Mod.RadarCoords = {}

  for chunk in game.surfaces.nauvis.get_chunks() do
    local top, left = chunk.x * 32, chunk.y * 32
    local bottom, right = top + 32, left + 32
    for _, radar in pairs(game.surfaces.nauvis.find_entities_filtered{area = {{top, left}, {bottom, right}}, name ="radar"}) do

      _addRadar(global.Mod.RadarCoords, radar)
    end
  end
end

function Events.rechart_base()
  log("Recharting...")
  local nChunks = 0
  local tChunks = 0
  local surf = game.surfaces.nauvis
  
  for k, v in ipairs(global.Mod.BaseCandidates) do
	game.forces['player'].chart(surf, v.x, v.y)
        nChunks = nChunks + 1
  end
  log(string.format("Recharted %d chunks.", nChunks))
end 

function Events.AddRadar(e)
  if e.created_entity ~= nil and e.created_entity.name == "radar" then
    radar = e.created_entity
    _addRadar(global.Mod.RadarCoords, radar)
  end
end

function Events.AddClonedRadar(e)
  if e.destination ~= nil and e.destination.name == "radar" then
    radar = e.destination
    _addRadar(global.Mod.RadarCoords, radar)
  end
end

function Events.RemoveRadar(e)
  log("Removing: " .. serpent.block(e.entity.name))
  if e.entity ~= nil and e.entity.name == "radar" then
    for k, v in ipairs(global.Mod.RadarCoords) do
      if v == e.entity.position then
        table.remove(global.Mod.RadarCoords, k)
      end
	end
	Events._findBaseCandidates()
  end
end

function Events.Init (e)
  log("Interval: " .. global.Mod.RechartInterval)
  script.on_nth_tick((global.Mod.RechartInterval * 60), Events.rechart_base)
end

return Events
