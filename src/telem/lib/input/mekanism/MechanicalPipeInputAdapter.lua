local o = require 'telem.lib.ObjectModel'
local t = require 'telem.lib.util'
local fn = require 'telem.vendor'.fluent.fn

local BaseMekanismInputAdapter = require 'telem.lib.input.mekanism.BaseMekanismInputAdapter'

local MechanicalPipeInputAdapter = o.class(BaseMekanismInputAdapter)
MechanicalPipeInputAdapter.type = 'MechanicalPipeInputAdapter'

function MechanicalPipeInputAdapter:constructor (peripheralName, categories)
    self:super('constructor', peripheralName)

    -- TODO this will be a configurable feature later
    self.prefix = 'mekpipe:'

    -- TODO make these constants
    local allCategories = {
        'basic',
        'transfer',
    }

    if not categories then
        self.categories = { 'basic' }
    elseif categories == '*' then
        self.categories = allCategories
    else
        self.categories = categories
    end

    self.queries = {
        basic = {
            filled_percentage   = fn():call('getFilledPercentage')
        },
        transfer = {
            buffer              = fn():call('getBuffer'):get('amount'):div(1000):fluid(),
            capacity            = fn():call('getCapacity'):div(1000):fluid(),
            needed              = fn():call('getNeeded'):div(1000):fluid(),
        }
    }

    -- TODO only supports energy and direction
    -- self:withGenericMachineQueries()
end

return MechanicalPipeInputAdapter