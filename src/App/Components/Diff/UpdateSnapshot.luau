local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Types = require(Argon.Types)
local Theme = require(App.Theme)
local stripProps = require(Util.stripProps)

local Hydrate = Fusion.Hydrate
local New = Fusion.New
local Children = Fusion.Children

local COMPONENT_ONLY_PROPS = {
    "Snapshot",
}

type Props = {
    Snapshot: Types.UpdatedSnapshot,
}

return function(props: Props): TextButton
	return Hydrate(New "TextButton" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Color3.new(0, 0, 1),
		Text = buffer.tostring(props.Snapshot.id),
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
