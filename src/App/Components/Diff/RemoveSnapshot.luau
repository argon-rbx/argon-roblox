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
    "Object",
}

type Props = {
    Object: Types.Ref | Instance,
}

return function(props: Props): TextButton
	return Hydrate(New "TextButton" {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Color3.new(1, 0, 0),
		Text =
            if typeof(props.Object) == "Instance" then props.Object:GetFullName()
            else buffer.tostring(props.Object),
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
