Attribute VB_Name = "basEvents"
' Winse - WINdows SErvices. IRC services for Windows.
' Copyright (C) 2004 The Winse Team [http://www.sourceforge.net/projects/winse]
'
' This program is free software; you can redistribute it and/or modify
' it under the terms of the GNU General Public License as published by
' the Free Software Foundation; either version 2 of the License, or
' (at your option) any later version.
'
' This program is distributed in the hope that it will be useful,
' but WITHOUT ANY WARRANTY; without even the implied warranty of
' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' GNU General Public License for more details.
'
' You should have received a copy of the GNU General Public License
' along with this program; if not, write to the Free Software
' Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
Option Explicit

'General IRC Events.
'When the channel is created.
'Parameters: Channel Joined (Channel), User Joined (User)
Public Const ChanCreate As String = "ChannelCreated"
'When a user joins the channel.
'Parameters: Channel Joined (Channel), User Joined (User)
Public Const ChanJoin As String = "ChannelJoined"
'When a user parts the channel.
'Parameters: Channel Parted (Channel), User Parted (User)
Public Const ChanPart As String = "ChannelParted"
'When the last user parts the channel.
'Parameters: Channel Parted (Channel), User Parted (User)
Public Const ChanDestroy As String = "ChannelDestroyed"
'When a user changes a member mode on a service.
'Parameters: Channel (Channel), Source Nick (String), Mode Change (+o, -a), Service Nick
Public Const ServiceChanModeChanged As String = "ServiceMemberModeChanged"
'Channel message.
'Parameters: Channel (Channel), Sender (User), PrefixTarget (String), Message (String)
Public Const ChanMsg As String = "ChannelMessage"
'Bot PrivateMessage.
'Parameters: Sender (User), Message (String)
Public Const BotMsg As String = "BotMessage"
'Client connecting
'Parameters: NewUser (User)
Public Const UserConnect As String = "UserConnect"
'Client changing nick
'Parameters: User (User), OldNick (String), NewNick (String)
Public Const UserNickChange As String = "UserRename"
'Client quitting
'Parameters: User (User), Reason (String)
Public Const UserQuit As String = "UserQuit"

'NickServ/AuthServ Events.
'User IDENTIFY. Parameters: User (User), Nick/Account Identified (String).
Public Const NSEventIdentify = "NickAuth"
