local tdg = {}

local buffer = require("IBUFFER")

local depthBuffer, mainFrustum, mainViewport, screenWidth, screenHeight
local objects = {}

tdg.index = {
    dot = 1, line = 2, triangle = 3
}
tdg.axis = {
    x = 1, y = 2, z = 2
}

function tdg.createFrustum(left, right, top, bottom, near, far)
    local delta  =   far - near
    local dir    = right - left
    local height =   top - bottom
    local near2  =     2 * near

    local m = { {}, {}, {}, {} }
    m[1] = 2 * near / dir
    m[2] = 0
    m[3] = (right + left) / dir
    m[4] = 0
    m[5] = 0
    m[6] = near2 / height
    m[7] = (top + bottom) / height
    m[8] = 0
    m[9] = 0
    m[10] = 0
    m[11] = -(far + near) / delta
    m[12] = -near2 * far / delta
    m[13] = 0
    m[14] = 0
    m[15] = -1
    m[16] = 0
  
    return m
end

function tdg.perspective(fov, ratio, near, far)
    local top    = math.tan(fov * 0.5) * near
    local bottom = -top
    local left   = ratio * bottom
    local right  = ratio * top

    return tdg.createFrustum(left, right, top, bottom, near, far)
end

function tdg.createViewport(x, y, width, height)
    return {x, y, width, height}
end

function tdg.createModelMatrix()
    return {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    }
end

function tdg.translate(matrix, x, y, z)
    matrix[4]  = x
    matrix[8]  = y
    matrix[12] = z
end

function tdg.floor(num)
    local floorNum = math.floor(num)
    if (num - floorNum >= 0.5) then
        return floorNum + 1
    end
    return floorNum
end

local function multiplyMatrix4ByCoords(m, coords)
    return {
        m[1]  * coords[1] + m[2]  * coords[2] + m[3]  * coords[3] + m[4]  * coords[4],
        m[5]  * coords[1] + m[6]  * coords[2] + m[7]  * coords[3] + m[8]  * coords[4],
        m[9]  * coords[1] + m[10] * coords[2] + m[11] * coords[3] + m[12] * coords[4],
        m[13] * coords[1] + m[14] * coords[2] + m[15] * coords[3] + m[16] * coords[4]
    }
end

local function multiplyMatrix4x4(m1, m2)
    return {
        m1[1]  * m2[1] + m1[2]  * m2[5] + m1[3]  * m2[9] + m1[4]  * m2[13], -- 1
        m1[1]  * m2[2] + m1[2]  * m2[6] + m1[3]  * m2[10] + m1[4]  * m2[14],-- 2
        m1[1]  * m2[3] + m1[2]  * m2[7] + m1[3]  * m2[11] + m1[4]  * m2[15],-- 3
        m1[1]  * m2[4] + m1[2]  * m2[8] + m1[3]  * m2[12] + m1[4]  * m2[16],-- 4

        m1[5]  * m2[1] + m1[6]  * m2[5] + m1[7]  * m2[9] + m1[8]  * m2[13], -- 5
        m1[5]  * m2[2] + m1[6]  * m2[6] + m1[7]  * m2[10] + m1[8]  * m2[14],-- 6
        m1[5]  * m2[3] + m1[6]  * m2[7] + m1[7]  * m2[11] + m1[8]  * m2[15],-- 7
        m1[5]  * m2[4] + m1[6]  * m2[8] + m1[7]  * m2[12] + m1[8]  * m2[16],-- 8

        m1[9]  * m2[1] + m1[10] * m2[5] + m1[11] * m2[9] + m1[12] * m2[13], -- 9
        m1[9]  * m2[2] + m1[10] * m2[6] + m1[11] * m2[10] + m1[12] * m2[14],-- 10
        m1[9]  * m2[3] + m1[10] * m2[7] + m1[11] * m2[11] + m1[12] * m2[15],-- 11
        m1[9]  * m2[4] + m1[10] * m2[8] + m1[11] * m2[12] + m1[12] * m2[16],-- 12

        m1[13] * m2[1] + m1[14] * m2[5] + m1[15] * m2[9] + m1[16] * m2[13], -- 13
        m1[13] * m2[2] + m1[14] * m2[6] + m1[15] * m2[10] + m1[16] * m2[14],-- 14
        m1[13] * m2[3] + m1[14] * m2[7] + m1[15] * m2[11] + m1[16] * m2[15],-- 14
        m1[13] * m2[4] + m1[14] * m2[8] + m1[15] * m2[12] + m1[16] * m2[16],-- 16
    }
end

local function normalizeCoords(coords)
    local wInverse = 1 / coords[4]
    return {coords[1] * wInverse, coords[2] * wInverse, coords[3] * wInverse}
end

local function getWindowCoords(normCoords, viewport)
    return {
        (normCoords[1] * 0.5 + 0.5) * viewport[3] + viewport[1],
        (normCoords[2] * 0.5 + 0.5) * viewport[4] + viewport[2],
        (1.0 + normCoords[3]) * 0.5
    }
end

local function print1DArray(array)
    for i = 1, #array do
        print(array[i])
    end
    print()
end

local function print2DArray(array)
    for i1 = 1, #array do
        local str = ""
        for i2 = 1, #array[i1] do
        str = str + array[i1][i2] + " "
        end
        print(str)
    end
    print()
end

function tdg.translateToScreen(modelMatrix)
    local eyeCoords    = multiplyMatrix4ByCoords(modelMatrix, {0, 0, 1, 1})
    local clipCoords   = multiplyMatrix4ByCoords(mainFrustum, eyeCoords)
    local normCoords   = normalizeCoords(clipCoords)
    local screenCoords = getWindowCoords(normCoords, mainViewport)
  
    screenCoords[1] = tdg.floor(screenCoords[1])
    screenCoords[2] = tdg.floor(screenCoords[2])
    screenCoords[3] = nil

    --print1DArray(eyeCoords)
    --print1DArray(clipCoords)
    --print1DArray(normCoords)
    --print1DArray(screenCoords)
    return screenCoords
end

function tdg.setScreenDimensions(width, height)
    screenWidth = width
    screenHeight = height
end

function tdg.setProperties(frustum, viewport)
    mainFrustum = frustum
    mainViewport = viewport
end

function tdg.clearDepthBuffer()
    depthBuffer = {}
    for h = 1, screenHeight do
        depthBuffer[h] = {}
        for w = 1, screenWidth do
            depthBuffer[h][w] = math.huge
        end
    end
end

function tdg.clearObjects()
    objects = {{}, {}, {}}
end

function tdg.rotateAroundX(x, y, z, angle)
    local sin, cos = math.sin(angle), math.cos(angle)
    return x, cos * y - sin * z, sin * y + cos * z
end

function tdg.rotateAroundY(x, y, z, angle)
    local sin, cos = math.sin(angle), math.cos(angle)
    return cos * x + sin * z, y, cos * z - sin * x
end

function tdg.rotateAroundZ(x, y, z, angle)
    local sin, cos = math.sin(angle), math.cos(angle)
    return cos * x - sin * y, sin * x + cos * y, z
end

function tdg.setPixel(x, y, depth, color)
    if x > 0 and x <= screenWidth and y > 0 and y <= screenHeight and depth < depthBuffer[y][x] then
        depthBuffer[y][x] = depth
        buffer.setDPixel(x, y, color, true)
    end
end

function tdg.rotateAround(angle, type)
    for i = 1, #objects[tdg.index.dot] do
        objects[tdg.index.dot][i][1], objects[tdg.index.dot][i][2], objects[tdg.index.dot][i][3] = type(objects[tdg.index.dot][i][1], objects[tdg.index.dot][i][2], objects[tdg.index.dot][i][3], angle)
    end
    for i = 1, #objects[tdg.index.line] do
        objects[tdg.index.line][i][1], objects[tdg.index.line][i][2], objects[tdg.index.line][i][3] = type(objects[tdg.index.line][i][1], objects[tdg.index.line][i][2], objects[tdg.index.line][i][3], angle)
        objects[tdg.index.line][i][4], objects[tdg.index.line][i][5], objects[tdg.index.line][i][6] = type(objects[tdg.index.line][i][4], objects[tdg.index.line][i][5], objects[tdg.index.line][i][6], angle)
    end
    for i = 1, #objects[tdg.index.triangle] do
        objects[tdg.index.triangle][i][1], objects[tdg.index.triangle][i][2], objects[tdg.index.triangle][i][3] = type(objects[tdg.index.triangle][i][1], objects[tdg.index.triangle][i][2], objects[tdg.index.triangle][i][3], angle)
        objects[tdg.index.triangle][i][4], objects[tdg.index.triangle][i][5], objects[tdg.index.triangle][i][6] = type(objects[tdg.index.triangle][i][4], objects[tdg.index.triangle][i][5], objects[tdg.index.triangle][i][6], angle)
        objects[tdg.index.triangle][i][7], objects[tdg.index.triangle][i][8], objects[tdg.index.triangle][i][9] = type(objects[tdg.index.triangle][i][7], objects[tdg.index.triangle][i][8], objects[tdg.index.triangle][i][9], angle)
    end
end

function tdg.translateAll(xAdd, yAdd, zAdd)
    for i = 1, #objects[tdg.index.dot] do
        objects[tdg.index.dot][i][1], objects[tdg.index.dot][i][2], objects[tdg.index.dot][i][3] = objects[tdg.index.dot][i][1] + xAdd, objects[tdg.index.dot][i][2] + yAdd, objects[tdg.index.dot][i][3] + zAdd
    end
    for i = 1, #objects[tdg.index.line] do
        objects[tdg.index.line][i][1], objects[tdg.index.line][i][2], objects[tdg.index.line][i][3] = objects[tdg.index.line][i][1] + xAdd, objects[tdg.index.line][i][2] + yAdd, objects[tdg.index.line][i][3] + zAdd
        objects[tdg.index.line][i][4], objects[tdg.index.line][i][5], objects[tdg.index.line][i][6] = objects[tdg.index.line][i][4] + xAdd, objects[tdg.index.line][i][5] + yAdd, objects[tdg.index.line][i][6] + zAdd
    end
    for i = 1, #objects[tdg.index.triangle] do
        objects[tdg.index.triangle][i][1], objects[tdg.index.triangle][i][2], objects[tdg.index.triangle][i][3] = objects[tdg.index.triangle][i][1] + xAdd, objects[tdg.index.triangle][i][2] + yAdd, objects[tdg.index.triangle][i][3] + zAdd
        objects[tdg.index.triangle][i][4], objects[tdg.index.triangle][i][5], objects[tdg.index.triangle][i][6] = objects[tdg.index.triangle][i][4] + xAdd, objects[tdg.index.triangle][i][5] + yAdd, objects[tdg.index.triangle][i][6] + zAdd
        objects[tdg.index.triangle][i][7], objects[tdg.index.triangle][i][8], objects[tdg.index.triangle][i][9] = objects[tdg.index.triangle][i][7] + xAdd, objects[tdg.index.triangle][i][8] + yAdd, objects[tdg.index.triangle][i][9] + zAdd
    end
end

function tdg.drawDot(x, y, z, color)
    if (z >= 0) then
        tdg.setPixel(x, y, z, color)
    end
end

function tdg.drawLine(x1, y1, z1, x2, y2, z2, color)
    if z1 >= 0 and z2 >= 0 then
        local incycleValueFrom, incycleValueTo, outcycleValueFrom, outcycleValueTo, isReversed, incycleValueDelta, outcycleValueDelta = x1, x2, y1, y2, false, math.abs(x2 - x1), math.abs(y2 - y1)
        if incycleValueDelta < outcycleValueDelta then
            incycleValueFrom, incycleValueTo, outcycleValueFrom, outcycleValueTo, isReversed, incycleValueDelta, outcycleValueDelta = y1, y2, x1, x2, true, outcycleValueDelta, incycleValueDelta
        end
        if outcycleValueFrom > outcycleValueTo then
            outcycleValueFrom, outcycleValueTo = outcycleValueTo, outcycleValueFrom
            incycleValueFrom, incycleValueTo = incycleValueTo, incycleValueFrom
            z1, z2 = z2, z1
        end
        local outcycleValue, outcycleValueCounter, outcycleValueTriggerIncrement = outcycleValueFrom, 1, incycleValueDelta / outcycleValueDelta
        local outcycleValueTrigger = outcycleValueTriggerIncrement
        local z, zStep = z1, (z2 - z1) / incycleValueDelta
        for incycleValue = incycleValueFrom, incycleValueTo, incycleValueFrom < incycleValueTo and 1 or -1 do
            if isReversed then
                tdg.setPixel(outcycleValue, incycleValue, z, color)
            else
                tdg.setPixel(incycleValue, outcycleValue, z, color)
            end
            outcycleValueCounter, z = outcycleValueCounter + 1, z + zStep
            if outcycleValueCounter > outcycleValueTrigger then
                outcycleValue, outcycleValueTrigger = outcycleValue + 1, outcycleValueTrigger + outcycleValueTriggerIncrement
            end
        end
    end
end

local function getTriangleDrawingShit(points)
    local topID, centerID, bottomID = 1, 1, 1
    for i = 1, 3 do
        points[i][2] = math.floor(points[i][2])
        if points[i][2] < points[topID][2] then topID = i end
        if points[i][2] > points[bottomID][2] then bottomID = i end
    end
    for i = 1, 3 do
        if i ~= topID and i ~= bottomID then centerID = i end
    end
    local yCenterMinusYTop = points[centerID][2] - points[topID][2]
    local yBottomMinusYTop = points[bottomID][2] - points[topID][2]
    local x1Screen, x2Screen = points[topID][1], points[topID][1]
    local x1ScreenStep = (points[centerID][1] - points[topID][1]) / yCenterMinusYTop
    local x2ScreenStep = (points[bottomID][1] - points[topID][1]) / yBottomMinusYTop
    local z1Screen, z2Screen = points[topID][3], points[topID][3]
    local z1ScreenStep = (points[centerID][3] - points[topID][3]) / yCenterMinusYTop
    local z2ScreenStep = (points[bottomID][3] - points[topID][3]) / yBottomMinusYTop
    return topID, centerID, bottomID, x1Screen, x2Screen, x1ScreenStep, x2ScreenStep, z1Screen, z2Screen, z1ScreenStep, z2ScreenStep
end


local function getTriangleSecondPartScreenCoordinates(points, centerID, bottomID)
    local yBottomMinusYCenter = points[bottomID][2] - points[centerID][2]
    return 
        points[centerID][1],
        (points[bottomID][1] - points[centerID][1]) / yBottomMinusYCenter,
        points[centerID][3],
        (points[bottomID][3] - points[centerID][3]) / yBottomMinusYCenter
end

local function fillPart(x1Screen, x2Screen, z1Screen, z2Screen, y, color)
    if x2Screen < x1Screen then
        x1Screen, x2Screen, z1Screen, z2Screen = x2Screen, x1Screen, z2Screen, z1Screen
    end
    local z, zStep = z1Screen, (z2Screen - z1Screen) / (x2Screen - x1Screen)
    for x = math.floor(x1Screen), math.floor(x2Screen) do
        tdg.setPixel(x, y, z, color)
        z = z + zStep
    end
end

function tdg.drawTriangle(points, color)
    if points[1][3] >= 0 or points[2][3] >= 0 or points[3][3] >= 0 then
        local topID, centerID, bottomID, x1Screen, x2Screen, x1ScreenStep, x2ScreenStep, z1Screen, z2Screen, z1ScreenStep, z2ScreenStep = getTriangleDrawingShit(points)
        for y = points[topID][2], points[centerID][2] - 1 do
            fillPart(x1Screen, x2Screen, z1Screen, z2Screen, y, color)
            x1Screen, x2Screen, z1Screen, z2Screen = x1Screen + x1ScreenStep, x2Screen + x2ScreenStep, z1Screen + z1ScreenStep, z2Screen + z2ScreenStep
        end
        x1Screen, x1ScreenStep, z1Screen, z1ScreenStep = getTriangleSecondPartScreenCoordinates(points, centerID, bottomID)
        for y = points[centerID][2], points[bottomID][2] do
            fillPart(x1Screen, x2Screen, z1Screen, z2Screen, y, color)
            x1Screen, x2Screen, z1Screen, z2Screen = x1Screen + x1ScreenStep, x2Screen + x2ScreenStep, z1Screen + z1ScreenStep, z2Screen + z2ScreenStep
        end
    end
end

function tdg.dot(x, y, z, color)
    return {x, y, z, color}
end

function tdg.line(x1, y1, z1, x2, y2, z2, color)
    return {x1, y1, z1, x2, y2, z2, color}
end

function tdg.triangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, color)
    return {x1, y1, z1, x2, y2, z2, x3, y3, z3, color}
end

function tdg.toDraw(object, type)
    table.insert(objects[type], object)
end

function tdg.draw()
    local modelMatrix = tdg.createModelMatrix()
    local screenCoords1, screenCoords2, screenCoords3
    for i, dot in pairs(objects[tdg.index.dot]) do
        if dot[3] >= 0 then
            tdg.translate(modelMatrix, dot[1] * -1, dot[2], dot[3])
            screenCoords1 = tdg.translateToScreen(modelMatrix)
            tdg.drawDot(screenCoords1[1], screenCoords1[2], dot[3], dot[4])
        end
    end
    for i, line in pairs(objects[tdg.index.line]) do
        if line[3] >= 0 or line[6] >= 0 then
            tdg.translate(modelMatrix, line[1] * -1, line[2], line[3])
            screenCoords1 = tdg.translateToScreen(modelMatrix)
            tdg.translate(modelMatrix, line[4] * -1, line[5], line[6])
            screenCoords2 = tdg.translateToScreen(modelMatrix)
            tdg.drawLine(screenCoords1[1], screenCoords1[2], line[3], screenCoords2[1], screenCoords2[2], line[6], math.random(1, 255))
        end
    end
    for i, triangle in pairs(objects[tdg.index.triangle]) do
        if triangle[3] >= 0 or triangle[6] >= 0 or triangle[9] >= 0 then
            tdg.translate(modelMatrix, triangle[1] * -1, triangle[2], triangle[3])
            screenCoords1 = tdg.translateToScreen(modelMatrix)
            tdg.translate(modelMatrix, triangle[4] * -1, triangle[5], triangle[6])
            screenCoords2 = tdg.translateToScreen(modelMatrix)
            tdg.translate(modelMatrix, triangle[7] * -1, triangle[8], triangle[9])
            screenCoords3 = tdg.translateToScreen(modelMatrix)
            local points = {{screenCoords1[1], screenCoords1[2], triangle[3]}, {screenCoords2[1], screenCoords2[2], triangle[6]}, {screenCoords3[1], screenCoords3[2], triangle[9]}}
            --tdg.drawTriangle(screenCoords1[1], screenCoords1[2], triangle[3], screenCoords2[1], screenCoords2[2], triangle[6], screenCoords3[1], screenCoords3[2], triangle[9], triangle[10])
            tdg.drawTriangle(points, triangle[10])
        end
    end
end

return tdg