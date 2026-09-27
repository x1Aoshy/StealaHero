-- ModuleScript helper. Call Prepare(importedModel, weaponId) after importing the FBX.
-- It clones the import, builds an actual Tool, and leaves the source model untouched.
-- Upload animations in Studio and connect your game's validated attack/damage logic separately.
local Kit = {}
local materialByPalette = {
    mjolnir_metal = Enum.Material.Metal, steel_dark = Enum.Material.Metal,
    silver = Enum.Material.Metal, gold = Enum.Material.Metal, cartridge_brass = Enum.Material.Metal,
    lightning = Enum.Material.Neon, web_neon = Enum.Material.Neon, gold_energy = Enum.Material.Neon,
    hammer_forged = Enum.Material.Metal, hammer_edge = Enum.Material.Metal, hammer_inlay = Enum.Material.Metal,
}
local gripRotations = {
    Mjolnir = CFrame.Angles(math.rad(-90), 0, 0),
    PowerPole = CFrame.Angles(math.rad(-90), 0, 0),
    PowerPole_GoldToy = CFrame.Angles(math.rad(-90), 0, 0),
    CapShield = CFrame.Angles(math.rad(-90), 0, 0),
    WebShooter = CFrame.identity,
    GomuFist = CFrame.Angles(math.pi, 0, 0),
}
local paletteForHandle = {
    Mjolnir = 'leather', PowerPole = 'hero_red', PowerPole_GoldToy = 'hero_red',
    CapShield = 'leather', WebShooter = 'web_red_cloth', GomuFist = 'rubber_skin',
}

function Kit.Prepare(importedModel: Model, weaponId: string): Tool
    assert(gripRotations[weaponId], 'Unknown weaponId')
    local source = importedModel:Clone()
    local handle = source:FindFirstChild('Handle', true)
    assert(handle and handle:IsA('BasePart'), 'Import must contain a BasePart named Handle')
    local tool = Instance.new('Tool')
    tool.Name = weaponId
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute('HeroWeaponId', weaponId)
    -- Preserve any import pivot offset before flattening the assembly into the Tool.
    local importOrigin = source:GetPivot()
    local originToHandle = importOrigin:ToObjectSpace(handle.CFrame)
    tool:SetAttribute('GripFromHand', gripRotations[weaponId] * originToHandle)
    for _, part in source:GetDescendants() do
        if part:IsA('BasePart') then
            local section = part:GetAttribute('Section') or part.Name:match('__([^_]+)__') or 'Handle'
            local palette = part:GetAttribute('Palette') or part.Name:match('__[^_]+__(.+)$') or paletteForHandle[weaponId]
            part:SetAttribute('HeroSection', section)
            part.Material = materialByPalette[palette] or Enum.Material.SmoothPlastic
            part.Anchored = false
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Massless = true
            part.Parent = tool
            if part ~= handle then
                local weld = Instance.new('Weld')
                weld.Name = 'HeroWeaponWeld'
                weld.Part0 = handle
                weld.Part1 = part
                weld.C0 = handle.CFrame:ToObjectSpace(part.CFrame)
                weld.Parent = part
            end
        end
    end
    handle.Name = 'Handle'
    source:Destroy()
    return tool
end

-- Run on the server when a Tool is equipped, after Roblox creates RightGrip.
function Kit.Attach(tool: Tool, character: Model)
    local hand = character:FindFirstChild('RightHand')
    assert(hand and hand:IsA('BasePart'), 'This kit requires an R15 avatar')
    local grip = hand:WaitForChild('RightGrip', 3)
    assert(grip and grip:IsA('Motor6D'), 'RightGrip was not created by Tool equip')
    local desired = tool:GetAttribute('GripFromHand')
    assert(typeof(desired) == 'CFrame', 'Run Prepare first')
    grip.C0 = CFrame.identity
    grip.C1 = desired:Inverse()
end

-- Client visual only. Call at the same elapsed time as Gomu_Pistol, then at t=0 to reset.
-- The imported meshes remain rigid; this stretches only the dedicated rubber section.
local stretchKeys = {{0,1},{.17,1.4},{.30,2.25},{.36,1.65},{.60,1}}
local caches = setmetatable({}, {__mode = 'k'})
function Kit.SetGomuTime(tool: Tool, elapsed: number)
    local cache = caches[tool]
    if not cache then
        cache = {}
        for _, part in tool:GetChildren() do
            if part:IsA('BasePart') and part.Name ~= 'Handle' then
                local weld = part:FindFirstChild('HeroWeaponWeld')
                if weld and weld:IsA('Weld') then
                    table.insert(cache, {part=part,weld=weld,size=part.Size,c0=weld.C0,section=part:GetAttribute('HeroSection')})
                end
            end
        end
        caches[tool] = cache
    end
    local stretch = 1
    for i=1,#stretchKeys-1 do
        local a,b = stretchKeys[i],stretchKeys[i+1]
        if elapsed >= a[1] and elapsed <= b[1] then
            local f = (elapsed-a[1])/(b[1]-a[1]); f = f*f*(3-2*f)
            stretch = a[2]+(b[2]-a[2])*f
            break
        end
    end
    for _, state in cache do
        if state.section == 'Rubber' then
            state.part.Size = Vector3.new(state.size.X, state.size.Y*stretch, state.size.Z)
            local p = state.c0.Position
            state.weld.C0 = CFrame.new(p.X,p.Y*stretch,p.Z)*state.c0.Rotation
        elseif state.section == 'Fist' then
            state.weld.C0 = CFrame.new(0,(stretch-1)*1.35,0)*state.c0
        end
    end
end
return Kit
