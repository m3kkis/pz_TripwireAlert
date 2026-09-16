require "Entity/ISUI/CraftRecipe/ISTiledIconPanel"

-- 42.20 debug Craft Recipes window calls this before entryBox exists.
local _setSearchInfoText = ISTiledIconPanel.setSearchInfoText
function ISTiledIconPanel:setSearchInfoText(_text)
    self.searchInfoText = _text
    if self.entryBox then
        _setSearchInfoText(self, _text)
    end
end
