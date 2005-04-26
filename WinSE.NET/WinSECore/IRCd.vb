'Copyright (c) 2005 The WinSE Team 
'All rights reserved. 
' 
'Redistribution and use in source and binary forms, with or without 
'modification, are permitted provided that the following conditions 
'are met: 
'1. Redistributions of source code must retain the above copyright 
'   notice, this list of conditions and the following disclaimer. 
'2. Redistributions in binary form must reproduce the above copyright 
'   notice, this list of conditions and the following disclaimer in the 
'   documentation and/or other materials provided with the distribution. 
'3. The name of the author may not be used to endorse or promote products 
'   derived from this software without specific prior written permission.

'THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR 
'IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
'OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
'IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
'INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
'NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
'DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
'THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
'(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF 
'THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
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
	SUPPORT_CHANNEL_FORCEJOIN = 1	 'Has ForceJoin command.
	SUPPORT_CHANNEL_FORCEPART = 2	 'Has a ForcePart (other than KICK).
	SUPPORT_CHANNEL_MODEHACK = 4	 'Have MODE hacking (so we don't have to have a service bot opped in there all the time).
	SUPPORT_CHANNEL_NETBURST = 8	 'IRCd has some strange form of netburst command.
	SUPPORT_CHANNEL_MASSDEOP = &H10	 'Has a command to mass-deop everyone.
	SUPPORT_CHANNEL_HALFOP = &H20	  'Supports +h - halfops.
	SUPPORT_CHANNEL_PROTECT = &H40	  'Supports protect mode
	SUPPORT_CHANNEL_OWNER = &H80	  'Supports channel owner
	SUPPORT_CHANNEL_BANEXMPT = &H100	 'Supports Channel Ban Exception.
	SUPPORT_CHANNEL_INVEX = &H200	  'Supports Channel Invite Exception.
	SUPPORT_USER_FORCENICK = &H400	  'Force a nick change.
	SUPPORT_USER_FORCEUMODE = &H800	  'Force a usermode change.
	SUPPORT_USER_SUPERKILL = &H1000	  'Has some form of "super kill" command.
	SUPPORT_USER_SVSOPER = &H2000	  'Has a command to set oper permissions.
	SUPPORT_USER_VHOST = &H4000	   'Supports Virtual Hosts
	SUPPORT_USER_VIDENT = &H8000	   'Supports Virtual Idents
	SUPPORT_SERVER_JUPESPECIAL = &H10000	 'Special command for server juping.
	SUPPORT_SERVER_SVSNOOPERS = &H20000	 'Supports disabling olines.
	SUPPORT_BAN_USERHOST = &H40000	  'Supports manual-expire user@host bans (AKill/GLine).
	SUPPORT_BAN_NICKNAME = &H80000	  'Supports manual-expire nickname bans (SQLine).
	SUPPORT_BAN_REALNAME = &H100000	  'Supports manual-expire realname bans (SGLine/SVSNLINE).
	SUPPORT_BAN_IPADDR = &H200000	   'Supports manual-expire IP Address bans (SZLine/GZLine).
	SUPPORT_TEMPBAN_USERHOST = &H400000	 'Supports autoexpire user@host bans (AKILL/GLine).
	SUPPORT_TEMPBAN_NICKNAME = &H800000	 'Supports autoexpire nickname bans (SQLine).
	SUPPORT_TEMPBAN_REALNAME = &H1000000	 'Supports autoexpire realname bans (SGLine?SVSNLINE).
	SUPPORT_TEMPBAN_IPADDR = &H2000000	  'Supports autoexpire IP Address bans (SZLine/GZLine).
	SUPPORT_UNBAN_USERHOST = &H4000000	  'Supports removing a user@host ban (RAKLL/UNGLine).
	SUPPORT_UNBAN_NICKNAME = &H8000000	  'Supports removing a nickname bans (UNSQLine).
	SUPPORT_UNBAN_REALNAME = &H10000000	  'Supports removing a realname ban (UNSGLine/SVSNLINE -).
	SUPPORT_UNBAN_IPADDR = &H20000000	  'Supports removing an IP Address ban (UNSZLine/UNGZLine).
	SUPPORT_HOLD_NICK = &H40000000	   'Supports setting a temporary hold on a nick.
	QUIRK_SUPERKILL_ACKNOWLEDGE = &H80000000	 'Servers acknowledge a "super kill".
	QUIRK_PROTECT_ISOPER = &H100000000	  'Protect mode is actually Admin (eg, Protect+ChanOp).
	QUIRK_OWNER_NOTOPER = &H200000000	   'Owner mode does not give ChanOp power (need to +o as well).
	QUIRK_INVEX_ONLY_INVONLY = &H400000000	 'Channel InvEx (+I) list only overrides +i (invite only).
	QUIRK_NOOPERS_LEAVES_OPERS = &H800000000	 'SVSNOOP does not deop existing opers.
	QUIRK_REHASH_WIPES_NOOPER = &H1000000000	 'REHASH clears NOOPER status.
	QUIRK_CHANHOLD_WONTKICK = &H2000000000	  'Channel hold doesn't automatically masskick everyone out.
	QUIRK_CHANHOLD_SENDSKICK = &H4000000000	 'IRCd will KICK everyone and send us a copy of each kick.
	QUIRK_CHANHOLD_IRCOPSIMMUNE = &H8000000000	 'IRCops aren't affected by channel holds.
	QUIRK_VIDENT_REPLACES_REALIDENT = &H10000000000	'VIdent replaces the real username.
	QUIRK_IDENTIFY_NO_LOGOUT = &H20000000000	'Cannot mark a user as having logged out.
End Enum

'This attribute can mark a command Sub that has an alias.
<AttributeUsage(AttributeTargets.Method, Inherited:=False, AllowMultiple:=True)> Public Class CommandAttribute
	Inherits Attribute
	Public ReadOnly CmdName As String
	Public ReadOnly CaseSensitive As Boolean
	Public Sub New(ByVal CmdName As String, ByVal CaseSensitive As Boolean)
		Me.CmdName = CmdName
		Me.CaseSensitive = CaseSensitive
	End Sub
End Class

'The class implemented by all IRCd protocol support classes.
Public MustInherit Class IRCd
	Protected ReadOnly c As Core
	Public Synched As Boolean
	Protected Sub New(ByVal c As Core)
		Me.c = c
		Synched = False
	End Sub
	Public Overridable Function ServiceUMode() As String
		Return "o"
	End Function
	Public Overridable Function InvisServiceUMode() As String
		Return "io"
	End Function
	Public Overridable Function EnforcerUMode() As String
		Return "i"
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
	Public MustOverride Sub SendToIRCops(ByVal Source As IRCNode, ByVal Message As String)
	Public MustOverride Sub SendToAll(ByVal Source As IRCNode, ByVal Message As String)
	Public MustOverride Overloads Sub SendToUMode(ByVal Source As IRCNode, ByVal Usermode As Char, ByVal Message As String)
	Public MustOverride Sub SendNumeric(ByVal Source As IRCNode, ByVal Target As IRCNode, ByVal Numeric As Integer, ByVal Format As String, ByVal ParamArray Parameters() As Object)
	Public MustOverride Sub SetChMode(ByVal Source As IRCNode, ByVal Channel As String, ByVal Mode As String)
	Public Overridable Sub DoNetBurst(ByVal Source As IRCNode, ByVal Channel As String, ByVal ts As Integer, ByVal Modes As String, ByVal ModeParams() As String, Optional ByVal Users()() As String = Nothing, Optional ByVal Bans() As String = Nothing, Optional ByVal Excepts() As String = Nothing, Optional ByVal Invites() As String = Nothing)
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
	Public Overridable Sub SetIdentify(ByVal Source As IRCNode, ByVal Target As String, ByVal Name As String)
	End Sub
	Public MustOverride Sub SQuitServer(ByVal Source As IRCNode, ByVal Server As String, ByVal Reason As String)
	Public MustOverride Sub SendError(ByVal Text As String)
	Public MustOverride Sub QuitUser(ByVal Who As User, ByVal Reason As String)
	Public MustOverride Sub KillUser(ByVal Source As IRCNode, ByVal Target As String, ByVal Reason As String, Optional ByVal SuperKill As Boolean = False)
	Public Overridable Sub SetOper(ByVal Source As IRCNode, ByVal Target As String, ByVal Flags As String)
	End Sub
	Public Overridable Sub SetVHost(ByVal Source As IRCNode, ByVal Target As User, ByVal VHost As String)
	End Sub
	Public Overridable Sub SetVIdent(ByVal Source As IRCNode, ByVal Target As User, ByVal VIdent As String)
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
	Public MustOverride Sub IntroduceClient(ByVal Nick As String, ByVal Username As String, ByVal Hostname As String, ByVal Realname As String, ByVal Usermodes As String, ByVal Numeric As Integer, ByVal Server As String, ByVal ts As Integer)
	Public MustOverride Sub IntroduceServer(ByVal Server As String, ByVal Hops As Integer, ByVal Numeric As Integer, ByVal Description As String, ByVal ts As Integer)
	Public MustOverride Sub LoginToServer()
	Public Overridable Sub EndSynch()
	End Sub
	Public MustOverride ReadOnly Property ChanModes() As String
	Public MustOverride ReadOnly Property UserModes() As String
	'This procedure can be invoked from ParseCmd() after ParseCmd has parsed the prefix, command, and arguments as appropriate.
	'Command handlers will have the same signature as this function.
	Protected Sub ExecuteCommand(ByVal sender As IRCNode, ByVal cmd As String, ByVal params() As String, ByVal rawcmd As String)
		Dim t As System.Type
		'We need to reflect the real type. Can we do this reliably from the base class...?
		c.Events.FireLogMessage("Protocol", "TRACE", "Preparing to reflect protocol class...")
		t = Me.GetType()
		'As a debugging measure, if we just reflected IRCd, we can't do anything...
		If t.Equals(GetType(IRCd)) Then
			'UGH. We reflected ourself. This is bad.
			c.Events.FireLogMessage("Protocol", "FATAL", "IRCd protocol base directly instantiated or unable to reflect derived class!")
			Throw New InvalidOperationException("IRCd protocol base directly instantiated or unable to reflect derived class!")
		End If
		'Otherwise, we're ok. Now find the method having the attribute and the right signature.
		Dim mi As System.Reflection.MethodInfo, ms As System.Reflection.MethodInfo()
		ms = t.GetMethods(Reflection.BindingFlags.Instance Or Reflection.BindingFlags.Public)
		'Yes we use two variables here. Reason is we have to find the first command that matches the criteria...
		For Each m As System.Reflection.MethodInfo In ms
			For Each ca As CommandAttribute In m.GetCustomAttributes(GetType(CommandAttribute), False)
				If ca.CaseSensitive Then
					If ca.CmdName = cmd Then
						mi = m
						Exit For
					End If
				Else
					If LCase(ca.CmdName) = LCase(cmd) Then
						mi = m
						Exit For
					End If
				End If
			Next
			If Not mi Is Nothing Then
				If mi.ReturnType Is Nothing Then
					c.Events.FireLogMessage("Protocol", "WARNING", String.Format("Handler {0}.{1} is bound to command {2} but doesn't have the correct signature!", t.ToString, mi.Name, cmd))
					mi = Nothing
				ElseIf mi.GetParameters.Length <> 4 Then
					c.Events.FireLogMessage("Protocol", "WARNING", String.Format("Handler {0}.{1} is bound to command {2} but doesn't have the correct signature!", t.ToString, mi.Name, cmd))
					mi = Nothing
				ElseIf Not mi.GetParameters()(0).ParameterType.Equals(GetType(IRCNode)) Then
					c.Events.FireLogMessage("Protocol", "WARNING", String.Format("Handler {0}.{1} is bound to command {2} but doesn't have the correct signature!", t.ToString, mi.Name, cmd))
					mi = Nothing
				ElseIf Not mi.GetParameters()(1).ParameterType.Equals(GetType(String)) Then
					c.Events.FireLogMessage("Protocol", "WARNING", String.Format("Handler {0}.{1} is bound to command {2} but doesn't have the correct signature!", t.ToString, mi.Name, cmd))
					mi = Nothing
				ElseIf Not mi.GetParameters()(2).ParameterType.Equals(GetType(String())) Then
					c.Events.FireLogMessage("Protocol", "WARNING", String.Format("Handler {0}.{1} is bound to command {2} but doesn't have the correct signature!", t.ToString, mi.Name, cmd))
					mi = Nothing
				ElseIf Not mi.GetParameters()(3).ParameterType.Equals(GetType(String)) Then
					c.Events.FireLogMessage("Protocol", "WARNING", String.Format("Handler {0}.{1} is bound to command {2} but doesn't have the correct signature!", t.ToString, mi.Name, cmd))
					mi = Nothing
				End If
			End If
			If Not mi Is Nothing Then Exit For
		Next
		If mi Is Nothing Then
			c.Events.FireLogMessage("Protocol", "ERROR", "Cannot find handler for command " + cmd)
			Return
		Else
			c.Events.FireLogMessage("Protocol", "TRACE", String.Format("Calling command function {0}.{1}", t.ToString(), mi.Name))
			Try
				mi.Invoke(Me, New Object() {sender, cmd, params, rawcmd})
			Catch ex As System.Reflection.TargetException
				c.Events.FireLogMessage("Protocol", "ERROR", String.Format("Command handler threw an {0}! {1}", ex.InnerException.GetType.ToString, ex.InnerException.Message))
			End Try
		End If
	End Sub
	Public Overridable Sub ParseCmd(ByVal Buffer As String)
	End Sub
	Public Overridable Function IsIRCop(ByVal u As User) As Boolean
		Return u.Usermodes.IndexOf("o"c) >= 0
	End Function
	Public Overridable Function IsSAdmin(ByVal u As User) As Boolean
		'Since RFC doesn't define "admin" of any kind, we'll default to just assume that all ircops are "admins".
		'Really though, +a is defined as some sort of admin in most modern ircds. In particular...
		'Unreal, Bahamut : +a == Services Admin
		'Hybrid : +a == Server Admin
		'IRCu doesn't have a concept of "admins".
		'Here's the wrench though :|, IRCnet's IRCD uses +a between servers for users that set /away :| .
		Return IsIRCop(u)
	End Function
End Class