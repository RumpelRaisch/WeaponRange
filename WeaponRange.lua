-- Weapon Range
--   by: Hanachi
--


require "math";
require "string";
require "lib/lib_InterfaceOptions"
require "lib/lib_LightWindow"
require "lib/lib_Slash"

--CONSTANTS
local FRAME = Component.GetFrame("RANGEFRAME")
local RAFRAME = Component.GetWidget("RANGETEXT")
local OnMessageOption = {}
local TEXTCOLOURS = {
    TEXT = {alpha = 1, tint = "00FF00", exposure = 0},
    OOR = {alpha = 1, tint = "FF0000", exposure = 0},
    FAR = {alpha = 1, tint = "FFFFFF", exposure = 0},
    GLOW = {tint = "0055FF"},
}
local TEXTOPTIONS = {
    FAR = "∞",
    PRE = "",
    SUF = " m",
    SEP = "|",
}
local StringTable = {
    One = "One",
    Two = "Two",
    Three = "Three",
    Four = "Four",
    Five = "Five",
    Six = "Six",
    Seven = "Seven",
    Eight = "Eight",
    Nine = "Nine",
}
local NumTable = {}
local TextTable = {}

-- INTERFACE OPTIONS INFO
InterfaceOptions.AddMovableFrame({
    frame = FRAME,
    label = "Weapon Range",
    scalable = true,
})

InterfaceOptions.StartGroup({id="ENABLED", label="Weapon Range", checkbox=true, default=true})
InterfaceOptions.AddCheckBox({id="WPN", label="Toggle for Ballistic Weapons", default=false})
InterfaceOptions.AddCheckBox({id="INPUT", label="Toggle for Menu's", default=false})
InterfaceOptions.AddCheckBox({id="MOVE", label="Toggle on Sprint", default=false})
InterfaceOptions.AddCheckBox({id="PLACE", label="Toggle on Calldown Place", default=false})
InterfaceOptions.AddCheckBox({id="VEHICLE", label="Toggle on enter Vehicle", default=false})
InterfaceOptions.StopGroup()
InterfaceOptions.StartGroup({id="OPTIONS", label="Display Options"})
InterfaceOptions.AddChoiceMenu({id="FONT", label="Font", default="UbuntuBold_9"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuBold_7", label="Ubuntu Bold - 7"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuBold_9", label="Ubuntu Bold - 9"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuBold_10", label="Ubuntu Bold - 10"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuBold_13", label="Ubuntu Bold - 13"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuMedium_8", label="Ubuntu Medium - 8"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuMedium_9", label="Ubuntu Medium - 9"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuMedium_10", label="Ubuntu Medium - 10"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="UbuntuMedium_11", label="Ubuntu Medium - 11"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Bold_10", label="Eurostile Bold - 10"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Bold_11", label="Eurostile Bold - 11"})
InterfaceOptions.AddChoiceEntry({menuId="FONT", val="Bold_13", label="Eurostile Bold - 13"})
InterfaceOptions.AddColorPicker({id="COLOR_TEXT", label="Range", default=TEXTCOLOURS.TEXT})
InterfaceOptions.AddColorPicker({id="COLOR_OOR", label="Out of range", default=TEXTCOLOURS.OOR})
InterfaceOptions.AddColorPicker({id="COLOR_FAR", label="Too far", default=TEXTCOLOURS.FAR})
InterfaceOptions.StopGroup()
InterfaceOptions.StartGroup({id="GLOWOPT", label="Glow", checkbox=true, default=true})
InterfaceOptions.AddColorPicker({id="COLOR_GLOW", label="Glow", default=TEXTCOLOURS.GLOW})
InterfaceOptions.StopGroup()
InterfaceOptions.StartGroup({id="TEXTOPTIONS", label="Text Options"})
InterfaceOptions.AddTextInput({id="TEXT_FAR", label="Far Text", default=TEXTOPTIONS.FAR, maxlen=32})
InterfaceOptions.AddTextInput({id="TEXT_PRE", label="Range Prefix", default=TEXTOPTIONS.PRE, maxlen=32})
InterfaceOptions.AddTextInput({id="TEXT_SUF", label="Range Suffix", default=TEXTOPTIONS.SUF, maxlen=32})
InterfaceOptions.StopGroup()
InterfaceOptions.StartGroup({id="MAX_RANGE", label="Max range Options"})
InterfaceOptions.AddCheckBox({id="MAX_RANGE_ENABLED", label="Show max range", default=true})
InterfaceOptions.AddTextInput({id="TEXT_SEP", label="Separator", default=TEXTOPTIONS.SEP, maxlen=3})
InterfaceOptions.StopGroup()

--VARIABLES

local enabled      = nil
local HUDShow      = nil
local alpha        = nil
local updatewidth  = nil
local aim          = nil
local message      = ""
local last         = nil
local distance     = nil
local runonce      = nil
local textformat   = ""
local HidePlace    = false
local HideMove     = false
local HideInput    = true
local Glow         = nil
local InVehicle    = false
local ShowMaxRange = true;

--EVENTS

function OnComponentLoad()
    InterfaceOptions.SetCallbackFunc(function(id, val)
        OnMessage({type=id, data=val})
    end, "Weapon Range")
end

function OnShow(args)
    FRAME:ParamTo("alpha", tonumber(args.show), args.dur);
end

function OnPlayerReady()
    UpdateMessage()
    if HideWeapon == "true" or HideWeapon == true then
        local info = Player.GetWeaponInfo()
        local bool = info.ReticleType == "PLASMA_CANNON" or info.ReticleType == "GRENADE_LAUNCHER"
        RAFRAME:Show(bool)
    end
end

function OnSeatChanged()
    if hideByVehicle then
        InVehicle = Player.IsInVehicle()
    else
        InVehicle = false
    end
end

function OnWeaponChanged()
    if HideWeapon == true or HideWeapon == "true" then
        local info = Player.GetWeaponInfo()
        log(tostring(info))
        local bool = info.ReticleType == "PLASMA_CANNON" or info.ReticleType == "GRENADE_LAUNCHER"
        RAFRAME:Show(bool)
    elseif enabled then
        RAFRAME:Show(true)
    end
end

function OnInputModeChanged(args)
    if hideByInput == true then
        HideInput = (args.mode == "game" or args.mode == "keyboard")
    end
end

function OnMovementModifier(args)
    if hideByMove == true then
        HideMove = args.mod
    end
end

function OnPlaceCalldown(args)
    if hideByPlace == true then
        HidePlace = args.placing
    end
end

function OnMessage(args)
    local option, message = args.type, args.data
    if not ( OnMessageOption[option] ) then log("["..option.."] Not Found") return nil end
    OnMessageOption[option](message)
end

OnMessageOption.ENABLED =
    function (message)
        enabled = (message == true or message == "true")
        SetOptionsAvailability()
        runonce = true
        if HideWeapon == true or HideWeapon == "true" then
            local info = Player.GetWeaponInfo()
            local bool = info.ReticleType == "PLASMA_CANNON" or info.ReticleType == "GRENADE_LAUNCHER"
            RAFRAME:Show(bool)
        else
            RAFRAME:Show(enabled)
        end
    end

OnMessageOption.FONT =
    function (message)
        RAFRAME:SetFont(message)
    end

OnMessageOption.GLOWOPT =
    function (message)
        Glow = message
    end

OnMessageOption.WPN =
    function (message)
        HideWeapon = message
        RAFRAME:Show(not HideWeapon)
    end

OnMessageOption.MAX_RANGE_ENABLED =
    function (message)
        ShowMaxRange = message;

        if true == ShowMaxRange or "true" == ShowMaxRange then
            InterfaceOptions.DisableOption("TEXT_SEP", false);
        else
            InterfaceOptions.DisableOption("TEXT_SEP", true);
        end
    end

OnMessageOption.INPUT =
    function (message)
        hideByInput = message
        if not hideByInput then
            HideInput = true
        end
    end

OnMessageOption.VEHICLE =
    function (message)
        hideByVehicle = message
        if message then
            InVehicle = false
        end
    end


OnMessageOption.MOVE =
    function(message)
        hideByMove = message
        if not hideByMove then
            HideMove = false
        end
    end

OnMessageOption.PLACE =
    function(message)
        hideByPlace = message
        if not hideByPlace then
            HidePlace = false
        end
    end

OnMessageOption.COLOR_TEXT =
    function (message)
        TEXTCOLOURS.TEXT = message
    end

OnMessageOption.COLOR_OOR =
    function (message)
        TEXTCOLOURS.OOR = message
    end

OnMessageOption.COLOR_FAR =
    function (message)
        TEXTCOLOURS.FAR = message
    end

OnMessageOption.COLOR_GLOW =
    function (message)
        TEXTCOLOURS.GLOW = message
    end
OnMessageOption.TEXT_FAR =
    function (message)
        if not message.text then
            TEXTOPTIONS.FAR = message
        else
            TEXTOPTIONS.FAR = message.text
        end
    end

OnMessageOption.TEXT_PRE =
    function (message)
        if not message.text then
            TEXTOPTIONS.PRE = message
        else
            TEXTOPTIONS.PRE = message.text
        end
    end

OnMessageOption.TEXT_SUF =
    function (message)
        if not message.text then
            TEXTOPTIONS.SUF = message
        else
            TEXTOPTIONS.SUF = message.text
        end
    end

OnMessageOption.TEXT_SEP =
    function (message)
        if not message.text then
            TEXTOPTIONS.SEP = message
        else
            TEXTOPTIONS.SEP = message.text
        end
    end

function SetOptionsAvailability()
    InterfaceOptions.DisableFrameMobility(FRAME, not enabled)
    InterfaceOptions.DisableOption("COLOR_OOR", not enabled)
    InterfaceOptions.DisableOption("COLOR_FAR", not enabled)
    InterfaceOptions.DisableOption("COLOR_TEXT", not enabled)
    InterfaceOptions.DisableOption("COLOR_GLOW", not enabled)
    InterfaceOptions.DisableOption("WPN", not enabled)
    InterfaceOptions.DisableOption("TEXT_FAR", not enabled)
    InterfaceOptions.DisableOption("TEXT_PRE", not enabled)
    InterfaceOptions.DisableOption("TEXT_SUF", not enabled)
    InterfaceOptions.DisableOption("TEXT_SEP", not enabled)
    InterfaceOptions.DisableOption("MAX_RANGE_ENABLED", not enabled)
end

--FUNCTIONS

function UpdateMessage()
    if not InVehicle then
        if (hideByInput ~= false or hideByMove ~= false or hideByPlace ~= false) then
            showRange = not ((not HideInput) or (HideMove) or (HidePlace))
        else
            showRange = enabled
        end
    else
        showRange = false
    end
    if (showRange) then
        local info = Player.GetWeaponInfo()
        if HideWeapon then
            local info = Player.GetWeaponInfo()
            local bool = info.ReticleType == "PLASMA_CANNON" or info.ReticleType == "GRENADE_LAUNCHER"
            RAFRAME:Show(bool)
        end
        distance = math.floor((Player.GetReticleInfo().Distance * 10) + 0.5) / 10;

        if nil ~= info then
            range = math.floor((info.Range * 10) + 0.5) / 10;
        else
            range = "0.0";
        end

        if distance ~= last then
            last = distance

            if distance == -1 then
                SetColour("FAR")
            elseif distance > tonumber(range) then
                SetColour("OOR")
            else
                SetColour("TEXT")
            end

            if (runonce == true or enabled == true or enabled == "true") then
                if distance == -1 then
                    local distance_f = string.find(tostring(distance), "%.");

                    if nil == distance_f then
                        distance = tostring(distance) .. ".0";
                    end

                    local text = TEXTOPTIONS.FAR;

                    if true == ShowMaxRange then
                        if "" ~= TEXTOPTIONS.SEP then
                            text = text .. " " .. TEXTOPTIONS.SEP .. " ";
                        end

                        text = text .. tostring(range) .. TEXTOPTIONS.SUF;
                    end

                    RAFRAME:SetText(text);
                else
                    local distance_f = string.find(tostring(distance), "%.");
                    local range_f = string.find(tostring(range), "%.");

                    if nil == distance_f then
                        distance = tostring(distance) .. ".0";
                    end

                    if nil == range_f then
                        range = tostring(range) .. ".0";
                    end

                    local text = TEXTOPTIONS.PRE .. tostring(distance) .. TEXTOPTIONS.SUF;

                    if true == ShowMaxRange then
                        if "" ~= TEXTOPTIONS.SEP then
                            text = text .. " " .. TEXTOPTIONS.SEP .. " ";
                        end

                        text = text .. tostring(range) .. TEXTOPTIONS.SUF;
                    end

                    RAFRAME:SetText(text);
                end
            end
        end
    else
        RAFRAME:SetText("")
    end
    runonce = false
    callback(UpdateMessage, nil, .01)
end

function SetColour(Format)
    RAFRAME:SetTextColor(TEXTCOLOURS[Format].tint)
    RAFRAME:SetParam("exposure", TEXTCOLOURS[Format].exposure)
    RAFRAME:SetParam("alpha", TEXTCOLOURS[Format].alpha)
    if Glow then
        RAFRAME:SetParam("glow", TEXTCOLOURS.GLOW.tint)
    else
        RAFRAME:SetParam("glow", 0)
    end
end
