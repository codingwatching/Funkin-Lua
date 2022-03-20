local utils = require "src.utils"

local sprite = {}

-- default data
local Sprite = {
    image = nil,
    xmlData = nil,
    animations = {},
    firstQuad = nil,

    curAnim = {
        name = '',
        quads = {},
        length = 0,
        framerate = 24,
        loop = false,
        finished = false
    },
    safeFrame = 1,
    curTime = 0
}
Sprite.__index = Sprite

function Sprite:update(dt)
    self.curTime = self.curTime + dt / (self.curAnim.framerate / 15)
    if self.curTime >= 1 then
        self.curTime = self.curTime - 1
    end
end

function Sprite:draw(x, y, r, sx, sy, ox, oy, kx, ky)
    local spriteNum = math.floor(self.curTime * self.curAnim.length) + 1
    if (not self.curAnim.loop and self.curAnim.finished) or self.curAnim.quads[spriteNum] == nil then
        spriteNum = self.safeFrame
    end

    local quad = self.curAnim.quads[spriteNum]
    if quad == nil then
        quad = self.firstQuad
    end

    love.graphics.draw(self.image, quad, x, y, r, sx, sy, ox, oy, kx, ky)

    if not self.curAnim.loop and spriteNum == self.curAnim.length then
        self.curAnim.finished = true
    end

    self.safeFrame = spriteNum
end

function Sprite:addAnim(name, prefix, indices, framerate, loop)
    if indices == nil then
        indices = {}
    end
    if framerate == nil then
        framerate = 24
    end
    if loop == nil then
        loop = true
    end

    local totalAnims = utils.tablelength(self.xmlData)

    for i = 1, totalAnims do
        local data = self.xmlData[i]

        if string.match(data["@name"], prefix) then
            local quads = {}
            local length = 0

            local loopThingy = totalAnims
            if indices ~= nil and indices ~= {} then
                loopThingy = indices
            end

            -- not good but im lazy to rewrite that
            for i = 1, loopThingy do
                local data = self.xmlData[i]
                if string.starts(data["@name"], prefix) then
                    if data["@frameX"] ~= nil then
                        data["@x"] = data["@x"] + data["@frameX"]
                    end
                    if data["@frameY"] ~= nil then
                        data["@y"] = data["@y"] + data["@frameY"]
                    end

                    if data["@frameWidth"] ~= nil then
                        data["@width"] = data["@frameWidth"]
                    end
                    if data["@frameHeight"] ~= nil then
                        data["@height"] = data["@frameHeight"]

                        -- hotfix idk
                        data["@y"] = data["@y"] + 2
                    end

                    local quad = love.graphics.newQuad(data["@x"], data["@y"], data["@width"], data["@height"],
                        self.image:getDimensions())

                    if self.firstQuad == nil then
                        self.firstQuad = quad
                    end

                    table.insert(quads, quad)
                    length = length + 1
                end
            end

            self.animations[name] = {
                name = name,
                quads = quads,
                length = length,
                framerate = framerate,
                loop = loop
            }

            break
        end
    end
end

function Sprite:playAnim(anim)
    self.curAnim = self.animations[anim]
    self.curAnim.finished = false
    self.safeFrame = 1
    self.curTime = 0
end

function sprite.newSprite(image, xml)
    local self = {}
    setmetatable(self, Sprite)

    self.image = image
    self.xmlData = utils.parseAtlas(xml)

    return self
end

return sprite
