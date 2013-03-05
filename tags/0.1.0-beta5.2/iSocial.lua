-----------------------------------
-- Setting up scope and libs
-----------------------------------

local AddonName, iSocial = ...;
LibStub("AceEvent-3.0"):Embed(iSocial);

local LDB = LibStub("LibDataBroker-1.1");

local _G = _G;

local iGuild, iFriends;

-------------------------------
-- Registering with iLib
-------------------------------

LibStub("iLib"):Register(AddonName, nil, iSocial);

----------------------
-- Initializing
----------------------

function iSocial:Boot()


if( not LibStub("iLib"):IsRegistered("iGuild") or not LibStub("iLib"):IsRegistered("iFriends") ) then
	return;
end

iGuild, iFriends = _G.iGuild, _G.iFriends;
if( not iFriends or not iGuild ) then
	return;
end

iGuild.ldb.OnEnter = function(anchor)
	if( iGuild:IsTooltip("Main") or not _G.IsInGuild() ) then
		return; -- When not in a guild, fires no tooltip. I dislike addons which show a tooltip with the info "You are not in a guild!".
	end
	
	local tip = iGuild:GetTooltip("Main", "UpdateTooltip");
	tip:Show();
	
	return tip;
end

iFriends.ldb.OnEnter = function(anchor)
	local showLocal, showBN = (#iFriends.Roster > 0 and iFriends.db.DisplayWoWFriends), (#iFriends.BNRoster > 0);
	local showBoth = (showLocal and showBN);
	
	if( iFriends:IsTooltip("BNet") or iFriends:IsTooltip("WoW") or (not showLocal and not showBN) ) then
		return; -- when no friends are present, we won't show a tooltip (I dislike that!).
	end
	
	_G.ShowFriends();
	
	local tip;
	
	if( showBN ) then
		tip = iFriends:GetTooltip("BNet", "UpdateTooltip");
		tip:Show();
	end

	return tip;
end
	
self.ldb = LDB:NewDataObject(AddonName, {
	type = "data source",
	text = "iSocial",
	icon = "Interface\\Addons\\iSocial\\Images\\iSocial",
});

self.ldb.OnEnter = function(anchor)
	self:HideAllTooltips();
	
	local iGtip, iFtip;
	iFtip = iFriends.ldb.OnEnter(anchor);
	iGtip = iGuild.ldb.OnEnter(anchor);
	
	local tip1, tip2;
	tip1 = iFtip and iFtip or iGtip;
	tip2 = iFtip and iGtip or nil;
	
	if( tip1 ) then
		tip1:SmartAnchorTo(anchor);
		
		if( tip2 ) then
			tip2:SetPoint("TOPLEFT", tip1, "BOTTOMLEFT", 0, 0);
			iSocial:SetSharedAutoHideDelay(0.25, tip1, tip2, anchor);
		else
			tip1:SetAutoHideDelay(0.25, anchor);
		end
	end
end

self.ldb.OnClick = function(_, button)
	if( _G.IsShiftKeyDown() ) then
		if( button == "LeftButton" ) then
			if( _G.IsAltKeyDown() and _G.CanGuildInvite() ) then
				_G.StaticPopup_Show("ADD_GUILDMEMBER");
			else
				_G.ToggleGuildFrame(1);
			end
		elseif( button == "RightButton" ) then
			iGuild:OpenOptions();
	--@do-not-package@
		elseif( button == "MiddleButton" ) then
			iGuild:CountAchievements();	
	--@end-do-not-package@
		end
	else
		if( button == "LeftButton" ) then
			if( _G.IsModifierKeyDown() ) then
				-- alt + left click = add new friend
				if( _G.IsAltKeyDown() ) then
					if( _G.BNFeaturesEnabledAndConnected() ) then
						-- I borrowed the following code snippet from the original WoW UI - (c) Blizzard
						_G.AddFriendEntryFrame_Collapse(true);
						_G.AddFriendFrame.editFocus = _G.AddFriendNameEditBox;
						_G.StaticPopupSpecial_Show(_G.AddFriendFrame);
						if( _G.GetCVarBool("addFriendInfoShown") ) then
							_G.AddFriendFrame_ShowEntry();
						else
							_G.AddFriendFrame_ShowInfo();
						end
						-- thanks Blizzard
					else
						_G.StaticPopup_Show("ADD_FRIEND");
					end
				end
			else
				-- normal click opens friends frame
				_G.ToggleFriendsFrame(1);
			end
		elseif( button == "RightButton" ) then
			if( not _G.IsModifierKeyDown() ) then
				iFriends:OpenOptions();
			end
		end
	end
end

LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged_iGuild_text", "UpdateBroker");
LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged_iFriends_text", "UpdateBroker");

self:UpdateBroker();
self:UnregisterEvent("PLAYER_ENTERING_WORLD");
end
iSocial:RegisterEvent("PLAYER_ENTERING_WORLD", "Boot");


function iSocial:UpdateBroker()
	self.ldb.text = "|cfffed100F:|r"..iFriends.ldb.text.." |cfffed100G:|r"..iGuild.ldb.text;
end