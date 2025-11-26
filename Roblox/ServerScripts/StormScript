local RunService = game:GetService("RunService")

local SEGMENTS = 2048           -- More segments = smoother circle
local WALL_THICKNESS = 2       -- Constant wall thickness
local STORM_HEIGHT = 350        -- Height of the wall
local STORM_RADIUS = 150       -- Radius from center
local STORM_CENTER = Vector3.new(0, 0, 0) -- You can change this

local function createStormRing(parentFolder, radius, height)
	local ringFolder = Instance.new("Folder")
	ringFolder.Name = "StormRing"
	ringFolder.Parent = parentFolder

	for i = 0, SEGMENTS - 1 do
		local angle = (2 * math.pi / SEGMENTS) * i

		-- position around circle
		local x = STORM_CENTER.X + math.cos(angle) * radius
		local z = STORM_CENTER.Z + math.sin(angle) * radius
		local y = STORM_CENTER.Y + height / 2  -- so it stands on ground

		local segmentLength = 2 * math.pi * radius / SEGMENTS

		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(10, 10, 20)
		part.Transparency = 0.05

		part.Size = Vector3.new(WALL_THICKNESS, height, segmentLength)

		-- Make it face the center
		local pos = Vector3.new(x, y, z)
		local lookAt = Vector3.new(STORM_CENTER.X, y, STORM_CENTER.Z)
		part.CFrame = CFrame.new(pos, lookAt) * CFrame.Angles(0, math.rad(90), 0)

		part.Parent = ringFolder
	end

	return ringFolder
end

-- Example usage:
local folder = Instance.new("Folder")
folder.Name = "StormVisuals"
folder.Parent = workspace

local stormRing = createStormRing(folder, STORM_RADIUS, STORM_HEIGHT)
