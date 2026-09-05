require "Entity/ISUI/CraftRecipe/ISTiledIconPanel"

local _setSearchInfoText = ISTiledIconPanel.setSearchInfoText
function ISTiledIconPanel:setSearchInfoText(_text)
    self.searchInfoText = _text
    if self.entryBox then
        _setSearchInfoText(self, _text)
    end
end

local _setDataList = ISTiledIconPanel.setDataList
function ISTiledIconPanel:setDataList(_dataList)
    if not _dataList then
        return
    end
    if not _dataList.getAllRecipes then
        local list = _dataList
        _dataList = {}
        function _dataList:getAllRecipes()
            return list
        end
    end
    _setDataList(self, _dataList)
end
