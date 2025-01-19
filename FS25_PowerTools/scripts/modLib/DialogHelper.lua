local g_currentModName = g_currentModName

DialogHelper = {}
function DialogHelper.showOptionDialog(parameters)
    -- local optionDialog = OptionDialog.new()

    -- g_gui:loadGui("dataS/gui/dialogs/OptionDialog.xml", "PTMenu", optionDialog)

    -- if parameters.callback and (type(parameters.callback)) == "function" then
    --     optionDialog:setCallback(parameters.callback, parameters.target, parameters.args)
    -- end

    -- if parameters.okButtonText ~= nil or parameters.cancelButtonText ~= nil then
    --     optionDialog:setButtonTexts(parameters.okButtonText, parameters.cancelButtonText)
    -- end

    -- optionDialog:setTitle(parameters.title or "")
    -- optionDialog:setOptions( parameters.options)

    -- local defaultOption = parameters.defaultOption or 1

    -- optionDialog.optionElement:setState( defaultOption)

    -- optionDialog:show()
    OptionDialog.createFromExistingGui({
        options = parameters.options,
        optionText = parameters.text,
        optionTitle = parameters.title,
        callbackFunc = parameters.callback,
    }, parameters.name or g_currentModName .. "OptionDialog")

    local optionDialog = OptionDialog.INSTANCE

    if parameters.okButtonText ~= nil or parameters.cancelButtonText ~= nil then
        optionDialog:setButtonTexts(parameters.okButtonText, parameters.cancelButtonText)
    end
    
    local defaultOption = parameters.defaultOption or 1

    optionDialog.optionElement:setState( defaultOption)

    if parameters.callback and (type(parameters.callback)) == "function" then
        optionDialog:setCallback(parameters.callback, parameters.target, parameters.args)
    end

end

function DialogHelper.showYesNoDialog(parameters)
    local yesNoDialog = YesNoDialog.new()

    g_gui:loadGui("dataS/gui/dialogs/YesNoDialog.xml", "YesNoDialog", yesNoDialog)

    if parameters.callback and (type(parameters.callback)) == "function" then
        yesNoDialog:setCallback(parameters.callback, parameters.target, parameters.args)
    end

    if parameters.okButtonText ~= nil or parameters.cancelButtonText ~= nil then
        yesNoDialog:setButtonTexts(parameters.okButtonText, parameters.cancelButtonText)
    end

    yesNoDialog:setTitle(parameters.title or "")

    yesNoDialog:show()
end

-- function DialogHelper.showSiloDialog(parameters)
--     --FIXME: not working
--     local siloDialog = SiloDialog.new()

--     g_gui:loadGui("dataS/gui/dialogs/SiloDialog.xml", "SiloDialog", siloDialog)

--     if parameters.callback and (type(parameters.callback)) == "function" then
--         siloDialog:setCallback(parameters.callback, parameters.target, parameters.args)
--     end

--     if parameters.okButtonText ~= nil or parameters.cancelButtonText ~= nil then
--         siloDialog:setButtonTexts(parameters.okButtonText, parameters.cancelButtonText)
--     end

--     siloDialog:setTitle(parameters.title or "")

--     siloDialog:show()
-- end


function DialogHelper.showTextInputDialog(parameters)
    -- local textInputDialog = TextInputDialog.new()
    -- local imePrompt = nil

    -- if parameters.isPasswordDialog then
    --     g_gui:loadGui("dataS/gui/dialogs/PasswordDialog.xml", "TextInputDialog", textInputDialog)
    -- else
    --     g_gui:loadGui("dataS/gui/dialogs/TextInputDialog.xml", "TextInputDialog", textInputDialog)
    -- end

    -- if parameters.callback and (type(parameters.callback)) == "function" then
    --     textInputDialog:setCallback(parameters.callback, parameters.target, parameters.defaultText, parameters.text, imePrompt, parameters.maxCharacters, parameters.args, parameters.isPasswordDialog, parameters.disableFilter)
    -- end

    -- if parameters.okButtonText ~= nil or parameters.cancelButtonText ~= nil then
    --     textInputDialog:setButtonTexts(parameters.okButtonText, parameters.cancelButtonText)
    -- end

    -- textInputDialog:setTitle(parameters.title or "") --NOTE: title is not used yet

    -- local textHeight, _ = textInputDialog.dialogTextElement:getTextHeight()
    -- textInputDialog:resizeDialog(textHeight)    

    -- textInputDialog:show()

    local applyTextFilter, imePrompt = false, nil

    TextInputDialog.show(parameters.callback, parameters.target, parameters.defaultText, parameters.title, imePrompt, parameters.maxCharacters, parameters.okButtonText, parameters.args, parameters.text, applyTextFilter)
end


--HACK: This is a back to solve a basegame bug
TextInputDialog.sendCallback = Utils.overwrittenFunction(TextInputDialog.sendCallback, function(self, superFunc, ...)
    superFunc(self, ...)
    self.textElement.maxCharacters = nil
end)
