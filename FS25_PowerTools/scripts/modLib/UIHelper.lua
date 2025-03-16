UIHelper = {}


function UIHelper.cloneButton(original, name, text, inputAction, callback, target)
    local button = original:clone(original.parent)
    button.name = name
    button:setText(text)
    button:setVisible(true)
    button.target = target or button.target
    -- button:setCallback("onClickCallback", callback)
    button.onClickCallback = callback
    if inputAction ~= nil then
        button:setInputAction(inputAction)
    end
    -- button:setInputAction(InputAction.FIND_USED_EQUIPMENT)
    button.parent:invalidateLayout()
    -- Log:var("title", title)
    return button
end

-- function UIHelper.createClonedButton(sibling, name, text, inputActionName, onClick)
--     local newButton = UIHelper.cloneButton(sibling, text, onClick)
--     -- newButton:applyProfile("buttonBuyUsed", true)
--     newButton.name = name

--     newButton.baseText = text

--     return newButton
-- end