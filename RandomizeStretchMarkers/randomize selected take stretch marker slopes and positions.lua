local item = reaper.GetSelectedMediaItem(0,0)
local take = reaper.GetTake(item,0)
local retval
local position
local srcpos
local length
local slope = 1

math.randomseed(os.time())
reaper.ShowConsoleMsg("\n**************************")
for i = 0, reaper.GetTakeNumStretchMarkers(take) do
  
  retval, position, srcpos = reaper.GetTakeStretchMarker(take, i)
  --slope = reaper.GetTakeStretchMarkerSlope(take, i)
  --reaper.ShowConsoleMsg("\nslope : {"..slope .. "}".."\npos : {"..position .. "}".."\nsrcpos : {"..srcpos .. "}".."\n===============")
  --length =  
  position = position + math.random(500)*0.01
  reaper.SetTakeStretchMarker(take,i,position)  
  
  slope = math.random(-100,100)* 0.01
  reaper.SetTakeStretchMarkerSlope(take,i,slope)
end     
