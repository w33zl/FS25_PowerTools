
DialogHelper = {}
function DialogHelper.showOptionDialog(parameters)
    local optionDialog = OptionDialog.new()

    -- optionDialog.onClose = function()
    -- end

    optionDialog.onClickOk = function()
        if parameters.callback and (type(parameters.callback)) == "function" then
            parameters.callback(parameters.target, optionDialog.optionElement.state, unpack(parameters.args))
        end
        optionDialog:close()
    end

    optionDialog.onClickBack = function()
        if parameters.cancelCallback and (type(parameters.cancelCallback)) == "function" then
            parameters.cancelCallback()
        end
        optionDialog:close()
    end

    g_gui:loadGui("dataS/gui/dialogs/OptionDialog.xml", "OptionDialog", optionDialog)

    optionDialog:setTitle(parameters.title or "")
    optionDialog:setOptions( parameters.options)

    local defaultOption = parameters.defaultOption or 1

    optionDialog.optionElement:setState( defaultOption)

    optionDialog:show()

end

function DialogHelper.showYesNoDialog(parameters)
    local optionDialog = OptionDialog.new()

    -- optionDialog.onClose = function()
    -- end

    optionDialog.onClickOk = function()
        if parameters.callback and (type(parameters.callback)) == "function" then
            parameters.callback(parameters.target, optionDialog.optionElement.state, unpack(parameters.args))
        end
        optionDialog:close()
    end

    optionDialog.onClickBack = function()
        if parameters.cancelCallback and (type(parameters.cancelCallback)) == "function" then
            parameters.cancelCallback()
        end
        optionDialog:close()
    end

    g_gui:loadGui("dataS/gui/dialogs/OptionDialog.xml", "OptionDialog", optionDialog)

    optionDialog:setTitle(parameters.title or "")
    optionDialog:setOptions( parameters.options)

    local defaultOption = parameters.defaultOption or 1

    optionDialog.optionElement:setState( defaultOption)

    optionDialog:show()

end

function DialogHelper.showTextInputDialog(parameters)
    local optionDialog = OptionDialog.new()

    -- optionDialog.onClose = function()
    -- end

    optionDialog.onClickOk = function()
        if parameters.callback and (type(parameters.callback)) == "function" then
            parameters.callback(parameters.target, optionDialog.optionElement.state, unpack(parameters.args))
        end
        optionDialog:close()
    end

    optionDialog.onClickBack = function()
        if parameters.cancelCallback and (type(parameters.cancelCallback)) == "function" then
            parameters.cancelCallback()
        end
        optionDialog:close()
    end

    g_gui:loadGui("dataS/gui/dialogs/OptionDialog.xml", "OptionDialog", optionDialog)

    optionDialog:setTitle(parameters.title or "")
    optionDialog:setOptions( parameters.options)

    local defaultOption = parameters.defaultOption or 1

    optionDialog.optionElement:setState( defaultOption)

    optionDialog:show()

end
