Line = Object:extend()

function Line:new(nodes, node_1_id, node_2_id)
    self.node_1_id, self.node_2_id = node_1_id, node_2_id
    local findNode = function(nodes, id)
        for _, node in pairs(nodes) do
            if node.id == id then return node end
        end
    end
    self.node_1, self.node_2 = findNode(nodes, node_1_id), findNode(nodes, node_2_id)
    self.selected = false
    self.color = {128, 128, 128, 64}

    self.points = getPointsAlongLine(10, self.node_1.x, self.node_1.y, self.node_2.x, self.node_2.y)
end

function Line:update(dt)
    local cx, cy = camera:getCameraCoords((self.node_1.x + self.node_2.x)/2, (self.node_1.y + self.node_2.y)/2, 0, 0, gw, gh)
    if cx < -40 or cx > gw + 40 then return end
    if cy < -40 or cy > gh + 40 then return end

    -- Three states: bought path (skill-point color, thick), linked to currently
    -- selected node (skill-point color, medium), idle (dim gray).
    local kb_id = current_room and current_room.selected_kb_node_id
    local linked_to_selection = (self.node_1.id == kb_id) or (self.node_2.id == kb_id)
    local both_bought = self.node_1.bought and self.node_2.bought

    local r, g, b = skill_point_color[1], skill_point_color[2], skill_point_color[3]
    if both_bought then
        self.selected = true
        self.color = {r/255, g/255, b/255, 1}             -- purchased path
        self.line_width = 2.5/camera.scale
    elseif linked_to_selection then
        self.selected = true
        self.color = {r/255, g/255, b/255, 1}
        self.line_width = 2/camera.scale
    else
        self.selected = false
        self.color = {128/255, 128/255, 128/255, 64/255}  -- idle: dim gray
        self.line_width = 1/camera.scale
    end
end

function Line:draw()
    local cx, cy = camera:getCameraCoords((self.node_1.x + self.node_2.x)/2, (self.node_1.y + self.node_2.y)/2, 0, 0, gw, gh)
    if cx < -40 or cx > gw + 40 then return end
    if cy < -40 or cy > gh + 40 then return end

    love.graphics.setLineWidth(self.line_width or (1/camera.scale))
    love.graphics.setColor(self.color)
    for i = 1, #self.points do
        local point = self.points[i]
        local next_point = self.points[i+1]
        if next_point then love.graphics.line(point.x, point.y, next_point.x, next_point.y) end
    end
    -- love.graphics.line(self.node_1.x, self.node_1.y, self.node_2.x, self.node_2.y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end
