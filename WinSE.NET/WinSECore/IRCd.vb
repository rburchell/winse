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
Option Explicit On 
Option Strict On
Option Compare Binary
Imports Microsoft.VisualBasic
Imports System
Imports System.Collections
Imports System.Collections.Specialized
'IRCd Protocol Support.
'Currently WinSE will only support textish protocols. Textish means that it is assumed that all protocols uses a Line End sequence
'to terminate an IRC message. The actual parsing of a message is up to the protcol definition. WinSE uses a default parser that assumes
'that commands look like this: [:sender ]COMMAND[ args] where args is either arg[ args] or :long arg. The command is dispatched via
'reflection.

'This enumeration is used to describe the ircd's supported features or quirks.
<Flags()> Public Enum IRCdSupportFlags As Long
	'Divide this into several parts...
	SUPPORT_CHANNEL_FORCEJOIN = 1	'Has ForceJoin command.
	SUPPORT_CHANNEL_FORCEPART = 2	'Has a ForcePart (other than KICK).
	SUPPORT_CHANNEL_MODEHACK = 4	'Have MODE hacking (so we don't have to have a service bot opped in there all the time).
	SUPPORT_CHANNEL_NETBURST = 8	'IRCd has some strange form of netburst command.
	SUPPORT_CHANNEL_MASSDEOP = &H10	'Has a command to mass-deop everyone.
	SUPPORT_CHANNEL_HALFOP = &H20	'Supports +h - halfops.
	SUPPORT_CHANNEL_PROTECT = &H40	'Supports protect mode
	SUPPORT_CHANNEL_OWNER = &H80	'Supports channel owner
	SUPPORT_CHANNEL_BANEXMPT = &H100	'Supports Channel Ban Exception.
	SUPPORT_CHANNEL_INVEX = &H200	'Supports Channel Invite Exception.
	SUPPORT_USER_FORCENICK = &H400	'Force a nick change.
	SUPPORT_USER_FORCEUMODE = &H800	'Force a usermode change.
	SUPPORT_USER_SUPERKILL = &H1000	'Has some form of "super kill" command.
	SUPPORT_USER_SVSOPER = &H2000	'Has a command to set oper permissions.
	SUPPORT_SERVER_JUPESPECIAL = &H4000	'Special command for server juping.
	SUPPORT_SERVER_SVSNOOPERS = &H8000	'Supports disabling olines.
	SUPPORT_BAN_USERHOST = &H10000	'Supports manual-expire user@host bans (AKill/GLine).
	SUPPORT_BAN_NICKNAME = &H20000	'Supports manual-expire nickname bans (SQLine).
	SUPPORT_BAN_REALNAME = &H40000	'Supports manual-expire realname bans (SGLine/SVSNLINE).
	SUPPORT_BAN_IPADDR = &H80000	'Supports manual-expire IP Address bans (SZLine/GZLine).
	SUPPORT_TEMPBAN_USERHOST = &H100000	'Supports autoexpire user@host bans (AKILL/GLine).
	SUPPORT_TEMPBAN_NICKNAME = &H200000	'Supports autoexpire nickname bans (SQLine).
	SUPPORT_TEMPBAN_REALNAME = &H400000	'Supports autoexpire realname bans (SGLine?SVSNLINE).
	SUPPORT_TEMPBAN_IPADDR = &H800000	'Supports autoexpire IP Address bans (SZLine/GZLine).
	SUPPORT_UNBAN_USERHOST = &H1000000	'Supports removing a user@host ban (RAKLL/UNGLine).
	SUPPORT_UNBAN_NICKNAME = &H2000000	'Supports removing a nickname bans (UNSQLine).
	SUPPORT_UNBAN_REALNAME = &H4000000	'Supports removing a realname ban (UNSGLine/SVSNLINE -).
	SUPPORT_UNBAN_IPADDR = &H8000000	'Supports removing an IP Address ban (UNSZLine/UNGZLine).
	SUPPORT_HOLD_NICK = &H10000000	'Supports setting a temporary hold on a nick.
	QUIRK_SUPERKILL_ACKNOWLEDGE = &H20000000	'Servers acknowledge a "super kill".
	QUIRK_PROTECT_ISOPER = &H40000000	'Protect mode is actually Admin (eg, Protect+ChanOp).
	QUIRK_OWNER_NOTOPER = &H80000000	'Owner mode does not give ChanOp power (need to +o as well).
	QUIRK_INVEX_ONLY_INVONLY = &H100000000	'Channel InvEx (+I) list only overrides +i (invite only).
	QUIRK_NOOPERS_LEAVES_OPERS = &H200000000	'SVSNOOP does not deop existing opers.
	QUIRK_REHASH_WIPES_NOOPER = &H400000000	'REHASH clears NOOPER status.
	QUIRK_CHANHOLD_WONTKICK = &H800000000	'Channel hold doesn't automatically masskick everyone out.
	QUIRK_CHANHOLD_SENDSKICK = &H1000000000	'IRCd will KICK everyone and send us a copy of each kick.
	QUIRK_CHANHOLD_IRCOPSIMMUNE = &H2000000000	'IRCops aren't affected by channel holds.
End Enum

'The class implemented by all IRCd protocol support classes.
Public MustInherit Class IRCd
	Protected ReadOnly c As Core
	Protected Sub New(ByVal c As Core)
		Me.c = c
	End Sub
	Public Overridable Function ServiceUMode() As String
		Return "o"
	End Function
	Public Overridable Function ChServiceUMode() As String
		Return "o"
	End Function
	Public Overridable Function InvisServiceUMode() As String
		Return "io"
	End Function
	Public MustOverride ReadOnly Property SupportFlags() As IRCdSupportFlags
	Public Overridable Sub ForceJoin(ByVal Source As IRCNode, ByVal Channel As String, ByVal User As String)
	End Sub
	Public Overridable Sub ForcePart(ByVal Source As IRCNode, ByVal Channel As String, ByVal User As String, ByVal Reason As String)
	End Sub
	Public MustOverride Sub JoinChan(ByVal Source As IRCNode, ByVal Channel As String)
	Public MustOverride Sub PartChan(ByVal Source As IRCNode, ByVal Channel As String, ByVal Reason As String)
	Public MustOverride Sub KickUser(ByVal Source As IRCNode, ByVal Channel As String, ByVal User As String, ByVal Reason As String)
	Public MustOverride Overloads Sub SendMessage(ByVal Source As IRCNode, ByVal Target As User, ByVal Message As String, ByVal Notice As Boolean)
	Public MustOverride Overloads Sub SendMessage(ByVal Source As IRCNode, ByVal Target As Channel, ByVal Message As String, ByVal Notice As Boolean)
	Public MustOverride Overloads Sub SendMessage(ByVal Source As IRCNode, ByVal Target As Channel, ByVal Prefix As Char, ByVal Message As String, ByVal Notice As Boolean)
	Public MustOverride Sub SetChMode(ByVal Source As IRCNode, ByVal Channel As String, ByVal Mode As String)
	Public Overridable Sub DoNetBurst(ByVal Source As IRCNode, ByVal Channel As String, ByVal ts As Integer, Optional ByVal Users()() As String = Nothing, Optional ByVal Bans() As String = Nothing, Optional ByVal Excepts() As String = Nothing, Optional ByVal Invites() As String = Nothing)
	End Sub
	Public Overridable Sub ClearList(ByVal Source As IRCNode, ByVal Channel As String, ByVal ModeCh As Char)
	End Sub
	Public Overridable ReadOnly Property VoiceChar() As Char
		Get
			Return "v"c
		End Get
	End Property
	Public Overridable ReadOnly Property HalfopChar() As Char
		Get
		End Get
	End Property
	Public Overridable ReadOnly Property ChanOpChar() As Char
		Get
			Return "o"c
		End Get
	End Property
	Public Overridable ReadOnly Property ProtectChar() As Char
		Get
		End Get
	End Property
	Public Overridable ReadOnly Property OwnerChar() As Char
		Get
		End Get
	End Property
	Public Overridable ReadOnly Property BanChar() As Char
		Get
			Return "b"c
		End Get
	End Property
	Public Overridable ReadOnly Property ExemptChar() As Char
		Get
			Return "e"c
		End Get
	End Property
	Public Overridable ReadOnly Property InviteChar() As Char
		Get
		End Get
	End Property
	Public Overridable Sub ForceNick(ByVal Source As IRCNode, ByVal Target As String, ByVal NewNick As String)
	End Sub
	Public Overridable Sub ForceUMode(ByVal Source As IRCNode, ByVal Target As String, ByVal Mode As String)
	End Sub
	Public MustOverride Sub SQuitServer(ByVal Source As IRCNode, ByVal Server As String, ByVal Reason As String)
	Public MustOverride Sub KillUser(ByVal Source As IRCNode, ByVal Target As String, ByVal Reason As String, Optional ByVal SuperKill As Boolean = False)
	Public Overridable Sub SetOper(ByVal Source As IRCNode, ByVal Target As String, ByVal Flags As String)
	End Sub
	Public Overridable Overloads Sub JupeSpecial(ByVal Source As IRCNode, ByVal Target As String, ByVal Reason As String)
	End Sub
	Public Overridable Overloads Sub JupeSpecial(ByVal Source As IRCNode, ByVal Target As String, ByVal Reason As String, ByVal Expiry As TimeSpan)
	End Sub
	Public Overridable Overloads Sub SetNoopers(ByVal Source As IRCNode, ByVal Target As String, ByVal Reason As String)
	End Sub
	Public Overridable Overloads Sub SetNoopers(ByVal Source As IRCNode, ByVal Target As String, ByVal Reason As String, ByVal Expiry As TimeSpan)
	End Sub
	Public Overridable Overloads Sub UnsetNoopers(ByVal Source As IRCNode, ByVal Target As String)
	End Sub
	Public Overridable Overloads Sub AddUserHostBan(ByVal Source As IRCNode, ByVal Mask As String, ByVal Reason As String)
	End Sub
	Public Overridable Overloads Sub AddUserhostBan(ByVal Source As IRCNode, ByVal Mask As String, ByVal Reason As String, ByVal Expiry As TimeSpan)
	End Sub
	Public Overridable Overloads Sub AddNicknameBan(ByVal Source As IRCNode, ByVal Mask As String, ByVal Reason As String)
	End Sub
	Public Overridable Overloads Sub AddNicknameBan(ByVal Source As IRCNode, ByVal Mask As String, ByVal Reason As String, ByVal Expiry As TimeSpan)
	End Sub
	Public Overridable Overloads Sub AddRealnameBan(ByVal Source As IRCNode, ByVal Mask As String, ByVal Reason As String)
	End Sub
	Public Overridable Overloads Sub AddRealnameBan(ByVal Source As IRCNode, ByVal Mask As String, ByVal Reason As String, ByVal Expiry As TimeSpan)
	End Sub
	Public Overridable Overloads Sub AddIPAddressBan(ByVal Source As IRCNode, ByVal Mask As String, ByVal Reason As String)
	End Sub
	Public Overridable Overloads Sub AddIPAddressBan(ByVal Source As IRCNode, ByVal Mask As String, ByVal Reason As String, ByVal Expiry As TimeSpan)
	End Sub
	Public Overridable Sub DelUserhostBan(ByVal Source As IRCNode, ByVal Mask As String)
	End Sub
	Public Overridable Sub DelNicknameBan(ByVal Source As IRCNode, ByVal Mask As String)
	End Sub
	Public Overridable Sub DelRealnameBan(ByVal Source As IRCNode, ByVal Mask As String)
	End Sub
	Public Overridable Sub DelIPAddressBan(ByVal Source As IRCNode, ByVal Mask As String)
	End Sub
	Public Overridable Sub SetNickHold(ByVal Source As IRCNode, ByVal Nick As String, ByVal [Set] As Boolean)
	End Sub
	Public MustOverride Sub SetChanHold(ByVal Source As IRCNode, ByVal Channel As String, ByVal [Set] As Boolean)
	Public MustOverride Function IsValidNumeric(ByVal Numeric As Integer, ByVal ServerNumeric As Boolean) As Boolean
	Public MustOverride Sub IntroduceClient(ByVal Nick As String, ByVal Username As String, ByVal Hostname As String, ByVal Realname As String, ByVal Usermodes As String, ByVal Numeric As String, ByVal Server As String, ByVal ts As Integer)
	Public MustOverride Sub IntroduceServer(ByVal Server As String, ByVal Hops As Integer, ByVal Numeric As String, ByVal Description As String, ByVal ts As Integer)
	Public MustOverride Sub LoginToServer()
	Public MustOverride ReadOnly Property ChanModes() As String
	Public MustOverride ReadOnly Property UserModes() As String
	Public Overridable Sub ParseCmd(ByVal Buffer As String)
	End Sub
End Class