local o = require 'telem.lib.ObjectModel'
local t = require 'telem.lib.util'

local OutputAdapter     = require 'telem.lib.OutputAdapter'
local MetricCollection  = require 'telem.lib.MetricCollection'

local GraphOutputAdapter = o.class(OutputAdapter)
GraphOutputAdapter.type = 'GraphOutputAdapter'

GraphOutputAdapter.MAX_ENTRIES = 50
GraphOutputAdapter.SCALE_TICK = 10

local function graphtrackrange (self)
    local min = math.huge
    local max = -math.huge

    for k,v in ipairs(self.graphdata) do
        if v < min then min = v end
        if v > max then max = v end
    end

    return min,max
end

function GraphOutputAdapter:constructor (frame, filter, bg, fg, maxEntries)
    self:super('constructor')

    self:cacheable()

    self.bBaseFrame = assert(frame, 'Frame is required')
    self.filter = assert(filter, 'Filter is required')
    
    self.graphdata = {}

    self.MAX_ENTRIES = maxEntries or self.MAX_ENTRIES

    self:register(bg, fg)
end

function GraphOutputAdapter:register (bg, fg)
    local currentmin = math.huge
    local currentmax = -math.huge

    self.tick = 0

    self.bInnerFrame = self.bBaseFrame:addFrame()
        :setBackground(bg)
        :setSize('parent.w + 1', 'parent.h')

    local fGraph = self.bInnerFrame:addFrame('fGraph'):setBackground(bg)
        :setPosition(1,1)
        :setSize('parent.w', 'parent.h - 6')

    local fLabel = self.bInnerFrame:addFrame('fLabel'):setBackground(bg)
        :setSize('parent.w', 4)
        :setPosition(1,'parent.h - 4')

    local fLabelMax = self.bInnerFrame:addFrame('fLabelMax'):setBackground(bg)
        :setSize(6, 1)
        :setPosition('parent.w - 6',1)

    local fLabelMin = self.bInnerFrame:addFrame('fLabelMin'):setBackground(bg)
        :setSize(6, 1)
        :setPosition('parent.w - 6','fLabel.y - 1')

    self.label = fLabel:addLabel()
        :setText("-----")
        :setPosition('parent.w/2-self.w/2', 2)
        :setForeground(fg)
        :setBackground(bg)

    self.graph = fGraph:addGraph()
        :setPosition(1,1)
        :setSize('parent.w - 1', 'parent.h - 1')
        :setMaxEntries(self.MAX_ENTRIES)
        :setBackground(bg)
        :setGraphColor(fg)
        :setGraphSymbol(' ')
    
    self.graphscale = fGraph:addGraph()
        :setGraphType('scatter')
        :setPosition(1,'parent.h')
        :setSize('parent.w - 1', 2)
        :setMaxEntries(self.MAX_ENTRIES)
        :setBackground(bg)
        :setGraphSymbol('|')

    self.labelmax = fLabelMax:addLabel()
        :setPosition(1,1)
        :setText('-----')
        :setForeground(fg)
        :setBackground(bg)
    
    self.labelmin = fLabelMin:addLabel()
        :setPosition(1,1)
        :setText('-----')
        :setForeground(fg)
        :setBackground(bg)

    -- self.graph:setMinValue(currentmin):setMaxValue(currentmax)
end

function GraphOutputAdapter:write (collection)
    assert(o.instanceof(collection, MetricCollection), 'Collection must be a MetricCollection')

    local resultMetric = collection:find(self.filter)

    assert(resultMetric, 'could not find metric')

    t.constrainAppend(self.graphdata, resultMetric.value, self.MAX_ENTRIES)

    local newmin, newmax = graphtrackrange(self)

    if newmin == newmax then
        newmin = newmin - 1
        newmax = newmax + 1
    end

    self.graph:setMinValue(newmin):setMaxValue(newmax)

    self.graph:addDataPoint(resultMetric.value)

    self.label:setFontSize(2)
    self.label:setText(t.shortnum(resultMetric.value))

    if self.tick == self.SCALE_TICK then
        self.graphscale:addDataPoint(100)
        self.tick = 1
    else
        self.graphscale:addDataPoint(50)
        self.tick = self.tick + 1
    end

    self.labelmax:setText(t.shortnum(newmax))
    self.labelmin:setText(t.shortnum(newmin))
    
    return self
end

function GraphOutputAdapter:getState ()
    local graphdata = {}

    for k,v in ipairs(self.graphdata) do
        graphdata[k] = v
    end

    return {
        graphdata = graphdata,
        tick = self.tick
    }
end

function GraphOutputAdapter:loadState (state)
    self.graphdata = state.graphdata
    self.tick = state.tick

    local newmin, newmax = graphtrackrange(self)

    if newmin == newmax then
        newmin = newmin - 1
        newmax = newmax + 1
    end

    self.graph:setMinValue(newmin):setMaxValue(newmax)

    for _,v in ipairs(self.graphdata) do
        self.graph:addDataPoint(v)

        if self.tick == self.SCALE_TICK then
            self.graphscale:addDataPoint(100)
            self.tick = 1
        else
            self.graphscale:addDataPoint(50)
            self.tick = self.tick + 1
        end
    end

    self.label:setFontSize(2)
    self.label:setText(t.shortnum(self.graphdata[#self.graphdata]))

    self.labelmax:setText(t.shortnum(newmax))
    self.labelmin:setText(t.shortnum(newmin))
end

return GraphOutputAdapter