VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CommandDispatcher"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
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

'This is the command dispatcher allocated in the new
'command parser. By (ab)using late binding, we can make
'implementing more commands easier by simply adding
'Public Subs here.

'All Subs here should have the same signature, which
'is:
'Public Sub <name>(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
'Note that Source is a String, which means for users,
'it will be the nick, NOT the UserID! The reason for
'this is because servers can send messages too, and
'we don't have server -> ID mapping (nor do I really
'plan on it :P ).
'RawCmd is the raw command stirng, in case we need it
'for some reason.

'As stated in basFunctions.ParseCmd, <name> is formatted
'as Cmd<name> for commands.

'Here is an example :P
Public Sub CmdPing(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    If UBound(Args) = 0 Then 'LBound() = 0, so 1 arg.
        basFunctions.SendData ":" + basMain.Config.ServerName + " PONG :" + Args(0)
    ElseIf UBound(Args) = 1 Then '2 args.
        basFunctions.SendData ":" + basMain.Config.ServerName = " PONG " + Args(0) + " :" + Args(1)
    End If
End Sub

Public Sub CmdPong(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)

End Sub

Public Sub CmdTKL(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'Idea: we can learn AKILLs set by the server in here :) .
    'Same Idea fo SZLINE SNLINE or SQLINE.
End Sub

Public Sub CmdError(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'Server is about to drop us.
    Call basFunctions.LogEventWithMessage(basMain.LogTypeError, RawCmd)
    'IMHO we shouldn't exactly splat here. We should
    'simply wait for the server to actually drop us
    '(which it might never do, depending on the nature
    'of the ERROR).
End Sub

Public Sub CmdNick(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    Dim sNick As String
    sNick = ExtractNickFromNUH(Source)
    If sNick = "" Or InStr(sNick, ".") > 0 Then
        'NEW USER!
        'Format:
        'NICK nick hops TS ident host server hops? :realname
        If UBound(Args) < 7 Then
            'EEP. NOT GOOD.
            basFunctions.NotifyAllUsersWithServicesAccess Replies.SanityCheckNICKInsufficientParameters
            Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " NICK :Not enough parameters")
            If UBound(Args) >= 0 Then
                'And just for the heck of it, remove the
                'poor user to avoid a desynch.
                Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " KILL + " + Args(0) + " :" + basMain.Config.ServerName + " (" + Args(0) + "(?) <- " + basMain.Config.UplinkName + ")")
            End If
            Exit Sub
        End If
        Dim u As User
        Set u = New User 'For later
        'Now check for a collision.
        If basFunctions.IsServicesNick(Args(0)) Then
            'COLLISION!!!!!!!!
            'For services nicks, we ALWAYS win.
            basFunctions.PutQuick ":" + basMain.Config.ServerName + " KILL " + Args(0) + " :" + basMain.Config.ServerName + " (Nick Collision (" + basMain.Config.UplinkName + " <- " + basMain.Config.ServerName + "))"
            'Send out a warning...
            Call basFunctions.LogEventWithMessage(basMain.LogTypeWarn, Replies.SanityCheckServicesNickInUse + Args(0) + "!" + Args(2) + "@" + Args(3))
            Exit Sub
        ElseIf Users.Exists(Args(0)) Then
            'COLLISION!!!!!!!!
            'Now a real server would do a Timestamp
            'check and remove the one with a more
            'recent stamp, but as we have no directly
            'connect users, and only one server, we
            'simply allow it - the IRCd wins.
            '(so theoretically, if we get here, we're fucked.)
            Set u = Users(Args(0))
            'Send out a warning...
            Call basFunctions.LogEventWithMessage(basMain.LogTypeWarn, "Collision: " + Args(0) + "!" + Args(2) + "@" + Args(3))
            'Overwrite the remaining fields.
        End If
        With u
            .Nick = Args(0)
            .SignOn = Args(2)
            .UserName = Args(3)
            .HostName = Args(4)
            .Server = Args(5)
            .RealName = Args(7)
            'Initialize the remaining fields.
            .AbuseTeam = False
            .Access = 0
            .EMail = ""
            .HideEMail = False
            .IdentifiedToNick = ""
            .MemoID = 0
            .Modes = ""
            .MsgStyle = Config.DefaultMessageType
            .Password = ""
            .Requests = 0
            .SvsStamp = 0
            .VirtHost = ""
        End With
        basMain.Users.Add u
        'send the MOTD, DADAA!!! --w00t
        'Dim Temp As New CommandDispatcher
        Call CmdMotd(Args(0), Args(), RawCmd)
        'WHY create a NEW CommandDispatcher when one is already available (Me)?
        'Set Temp = Nothing
        'Thanks to command callbacks, we don't have to
        'muck with registered nicks here!
    Else
        'NICK CHANGE!
        'FIRST things, first if this is just a case
        'change, then screw it.
        If UCase(sNick) = UCase(Args(0)) Then Exit Sub
        'Now check for a collision.
        If basFunctions.IsServicesNick(Args(0)) Then
            'COLLISION!!!!!!!!
            'For services nicks, we ALWAYS win.
            basFunctions.PutQuick ":" + basMain.Config.ServerName + " KILL " + Args(0) + " :" + basMain.Config.ServerName + " (Nick Collision (" + basMain.Config.UplinkName + " <- " + basMain.Config.ServerName + "))"
            'Remove the user (under his old nick) from our data.
            Users(sNick).Dispose
            'Send out a warning...
            Call basFunctions.LogEventWithMessage(basMain.LogTypeWarn, Replies.SanityCheckServicesNickInUse + Args(0) + "!" + Args(2) + "@" + Args(3))
            Exit Sub
        ElseIf Users.Exists(Args(0)) Then
            'COLLISION!!!!!!!!
            'This is s nickchange... so all I can say
            'is... WTF?
            Users(Args(0)).KillUser "Nick Collision (" + basMain.Config.UplinkName + " <- " + basMain.Config.ServerName + ")", basMain.Config.ServerName
            'Send out a warning...
            Call basFunctions.LogEventWithMessage(basMain.LogTypeWarn, Replies.SanityCheckNickChangeCollision + Args(0) + "!" + Args(2) + "@" + Args(3))
            Exit Sub
        End If
        'Otherwise, we're ok.
        Users(ExtractNickFromNUH(Source)).Nick = Args(0)
        'Thanks to command callbacks, we don't have to
        'muck with registered nicks here!
    End If
End Sub

Public Sub CmdNotice(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'Dummy proc.
End Sub

Public Sub CmdPrivMsg(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'PARAMETER CHECK
    If ExtractNickFromNUH(Source) = "" Or InStr(ExtractNickFromNUH(Source), ".") > 0 Then
        'Ignore server crap.
        Exit Sub
    End If
    If InStr(Source, "$") > 0 Then
        'Ignore server-wide messages :P .
        Exit Sub
    End If
    Dim sNick As String
    sNick = ExtractNickFromNUH(Source)
    'Format:
    ':source PRIVMSG dest :msg
    If UBound(Args) < 0 Then
        'No nickname!
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckPRIVMSGInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 411 " + basMain.Config.UplinkName + " :No recepient given (PRIVMSG)")
        Exit Sub
    End If
    If UBound(Args) < 1 Then
        'No message!
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckPRIVMSGInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 412 " + basMain.Config.UplinkName + " :No text to send")
    End If
    'Now one thing we need to deal with is CTCP crap.
    Dim sCTCP As String, sCTCPArgs As String
    If Left(Args(1), 1) = MIRC_CTCP Then
        sCTCP = Mid(Args(1), 2)
        If Right(sCTCP, 1) = MIRC_CTCP Then sCTCP = Left(sCTCP, Len(sCTCP) - 1)
        If InStr(sCTCP, " ") > 0 Then
            sCTCPArgs = Mid(sCTCP, InStr(sCTCP, " ") + 1)
            sCTCP = Left(sCTCP, InStr(sCTCP, " ") - 1)
        End If
        Select Case sCTCP
            Case "PING"
                basFunctions.LogEventWithMessage LogTypeNotice, sNick & " pinged " & Args(0) & " (" & Args(1) & ")"
                basFunctions.Notice Args(0), sNick, MakeCTCP("PING " + Args(1))
            Case "VERSION"
                basFunctions.LogEventWithMessage LogTypeNotice, sNick & " versioned " & Args(0) & " (" & Args(1) & ")"
                basFunctions.Notice Args(0), sNick, MakeCTCP("VERSION " + basMain.AppName + " " + basMain.AppVersion + "-" + basMain.AppCompileInfo + " " + basMain.AppCompileDate)
        End Select
    End If
    'First send out the PRIVMSG.
    Select Case UCase(ExtractNickFromNUH(Args(0)))
        Case "NICKSERV"
            sNickServ.NickservHandler Args(1), basMain.Users(sNick)
        Case "CHANSERV"
            sChanServ.ChanservHandler Args(1), basMain.Users(sNick)
        Case "MEMOSERV"
            sMemoServ.MemoservHandler Args(1), basMain.Users(sNick)
        Case "OPERSERV"
            sOperServ.OperservHandler Args(1), basMain.Users(sNick)
        Case "BOTSERV"
            sBotServ.BotservHandler Args(1), basMain.Users(sNick)
        Case "AGENT"
            sAgent.AgentHandler Args(1), basMain.Users(sNick)
        Case "ADMINSERV"
            sAdminServ.AdminservHandler Args(1), basMain.Users(sNick)
        Case "DEBUGSERV"
            sDebugServ.DebugservHandler Args(1), basMain.Users(sNick)
        Case "HOSTSERV"
            sHostServ.HostservHandler Args(1), basMain.Users(sNick)
        Case "MASSERV"
            sMassServ.MassservHandler Args(1), basMain.Users(sNick)
        Case "ROOTSERV"
            sRootServ.RootservHandler Args(1), basMain.Users(sNick)
        Case Else 'Bot/Channel?
    End Select
    'Now do flood crap.
    Call basMain.Users(sNick).CheckFloodLevel
End Sub

Public Sub CmdSMo(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    frmServer.tmrEoS.Enabled = True
End Sub

Public Sub CmdKill(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'PARAMETER CHECK
    Dim sNick As String, bSrvKill As Boolean
    sNick = ExtractNickFromNUH(Source)
    If sNick = "" Or InStr(sNick, ".") > 0 Then
        'SERVER KILL.
        bSrvKill = True
    End If
    If UBound(Args) < 1 Then
        'BLAH
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckKILLInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " KILL :Not enough parameters")
    End If
    'Now is it a user?
    If basMain.Users.Exists(ExtractNickFromNUH(Args(0))) Then
        Dim u As User
        Set u = basMain.Users(ExtractNickFromNUH(Args(0)))
        'Let admins know.
        'Change this to make it look like IRCd KILL notices.
        Call LogEventWithMessage(basMain.LogTypeNotice, "Received KILL message for " + u.Nick + "!" + u.UserName + "@" + u.HostName + " from " + sNick + " Path: " + Args(1))
        'Remove it.
        Dim s(0) As String
        'Note on Local Kills: most IRCds send these out as QUIT :Local kill by <oper> (<reason>)
        'so we don't have to determine the difference here :) .
        s(0) = "KILL " + Args(1)
        Call CmdQuit(Args(0), s, RawCmd)
    ElseIf IsServicesNick(ExtractNickFromNUH(Args(0))) Then
        'ARRRGH! BAD OPER! *SPANK*
        Dim i As Integer
        For i = 0 To basMain.TotalServices - 1
            If UCase(Args(0)) = UCase(basMain.Service(i).Nick) Then
                Call basFunctions.IntroduceClient(basMain.Service(i).Nick, basMain.Service(i).Hostmask, basMain.Service(i).Name)
            End If
        Next
        Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, Replace(Replies.UserKilledService, "%n", sNick))
        'IMHO, we should have configurable punishments here. My thoughts are:
        'Warn: Just tell the user not to kill services. Remember, we may have ChanServ sitting in a channel,
        '      so an oper may accidentally kill ChanServ (or a BotServ bot) by hitting TAB not enough/too
        '      many times.
        'Deoper: DEOPER the user.
        'Deny: DEOPER and DENY.
        'Kill: We send a KILL
        'SuperKill: We send an SVSKill.
        'GLine: We send an AKILL/GLINE/TKL + G (temp).
        'PGLine: We send a perm AKILL/GLINE/TKL + G.
        'Other?
        If Not bSrvKill Then Call Users(sNick).KillUser(Replies.KillReasonKilledService)
    End If
End Sub

Public Sub CmdQuit(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    Dim sNick As String
    sNick = ExtractNickFromNUH(Source)
    If sNick = "" Or InStr(sNick, ".") > 0 Then
        'WTF?
        Call LogEventWithMessage(LogTypeError, Replies.SanityCheckIRCdSentQuitForServer)
        Exit Sub
    End If
    Dim i As Integer
    'Otherwise...
    'Part them from all channels.
    Dim s(0) As String
    s(0) = "0"
    'Emulate a JOIN 0 AKA PARTALL.
    Call CmdJoin(Source, s, RawCmd)
    'Invalidate the user record.
    If Users.Exists(sNick) = False Then
        'WTF? *SPLAT*
        Call basFunctions.LogEventWithMessage(LogTypeError, Replies.SanityCheckLostUser)
        Exit Sub
    End If
    Users(sNick).Dispose
    'K that outta do it :)
End Sub

Public Sub CmdMode(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'PARAMETER CHECK
    Dim sNick As String, bSrvMode As Boolean
    sNick = ExtractNickFromNUH(Source)
    If sNick = "" Or InStr(sNick, ".") > 0 Then
        'SERVER MODE! (ServerOP?)
        bSrvMode = True
    End If
    If UBound(Args) < 1 Then
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckMODEInsufficientParameters)
        basFunctions.PutQuick ":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " MODE :Not enough parameters"
    End If
    'Otherwise, send it on it's merry way to the spiffy
    '(correct) mode parser...
    Dim sModeString As String
    sModeString = Join(Args, " ")
    sModeString = Mid(sModeString, InStr(sModeString, " ") + 1)
    If Users.Exists(Args(0)) Then
        Users(Args(0)).SetUserModes sModeString
    ElseIf Channels.Exists(Args(0)) Then
        Channels(Args(0)).SetChannelModes Source, sModeString
    Else
        'EEEEEEEEEEEEEEEK!
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replace(Replies.SanityCheckMODENonExistantEntity, "%n", Args(0)))
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 401 " + basMain.Config.UplinkName + " " + Args(0) + " :No such nick/channel")
    End If
    'Ja mata! (I love stealing eggdrop quotes :P )
End Sub

Public Sub CmdJoin(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'PARAMETER CHECK
    Dim sNick As String
    sNick = ExtractNickFromNUH(Source)
    If sNick = "" Or InStr(sNick, ".") > 0 Then
        'WTF? Servers can't join channels...
        Exit Sub
    End If
    If UBound(Args) < 0 Then
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckJOINInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " JOIN :Not enough parameters")
    End If
    Dim chns As Variant, i As Integer, v As Variant, u As User, c As Channel, cm As ChannelMember
    Set u = Users(sNick)
    chns = Split(Args(0), ",")
    Dim sChan As Variant
    For Each sChan In chns
        If sChan = "0" Then
            For Each v In u.Channels
                Dim s(0) As String
                s(0) = Channels(v).Name
                Call CmdPart(Source, s, RawCmd)
            Next v
        Else
            If Channels.Exists(sChan) = False Then
                'NEW CHANNEL!
                Set c = New Channel
                With c
                    .Name = sChan
                    Set cm = New ChannelMember
                    Set cm.Member = u
                    cm.Modes = ""
                    .Members.Add cm
                    'Initialize the rest.
                    .ChannelKey = ""
                    .FloodProtection = ""
                    .Modes = ""
                    .OverflowChannel = ""
                    .OverflowLimit = 0
                    .Topic = ""
                    .TopicSetBy = ""
                    .TopicSetOn = 0
                End With
                Channels.Add c
                u.Channels.Add c
            Else
                With Channels(sChan)
                    If .Members.Exists(u.Nick) Then Exit Sub 'Already on the channel.
                    Set cm = New ChannelMember
                    On Error Resume Next
                    Set cm.Member = u
                    cm.Modes = ""
                    .Members.Add cm
                    On Error GoTo 0
                End With
            End If
        End If
    Next sChan
End Sub

Public Sub CmdPart(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'PARAMETER CHECK
    Dim sNick As String
    sNick = ExtractNickFromNUH(Source)
    If sNick = "" Or InStr(sNick, ".") > 0 Then
        'WTF? Servers can't join channels...
        Exit Sub
    End If
    If UBound(Args) < 0 Then
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckPARTInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " PART :Not enough parameters")
    End If
    Dim chns As Variant, i As Integer, u As User
    Set u = Users(sNick)
    chns = Split(Args(0), ",")
    Dim sChan As Variant
    For Each sChan In chns
        u.Channels.Remove sChan
        With Channels(sChan)
            On Error Resume Next
            .Members.Remove u.Nick
            If .Members.Count = 0 Then
                'Invalidate the channel, as it is now
                'empty.
                Channels.Remove sChan
            End If
        End With
    Next sChan
End Sub

Public Sub CmdTopic(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'PARAMETER CHECK
    Dim sNick As String
    sNick = ExtractNickFromNUH(Source)
    If UBound(Args) < 1 Then
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckTOPICInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " TOPIC :Not enough parameters")
    ElseIf UBound(Args) = 1 Then
        With Channels(Args(0))
            .Topic = Args(1)
            .TopicSetBy = Source
            .TopicSetOn = basUnixTime.GetTime
        End With
    ElseIf UBound(Args) > 1 And UBound(Args) < 3 Then
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckTOPICInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " TOPIC :Not enough parameters")
    ElseIf UBound(Args) >= 3 Then
        With Channels(Args(0))
            .Topic = Args(3)
            .TopicSetBy = Args(1)
            .TopicSetOn = Args(2)
        End With
    End If
End Sub

Public Sub CmdSetHost(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    Dim sNick As String
    sNick = ExtractNickFromNUH(Source)
    If sNick = "" Or InStr(sNick, ".") > 0 Then
        'WHAAAAAT? Servers don't have vhosts!
        Exit Sub
    End If
    If UBound(Args) < 0 Then
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckSETHOSTInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " SETHOST :Not enough parameters")
    End If
    Dim i As Integer, u As User
    Set u = Users(sNick)
    If UCase(Config.ServerType) = "UNREAL" Then
        Call u.SetUserModes("+xt")
    Else
        'Are there other IRCds that do modechange with
        'SETHOST?
    End If
    u.VirtHost = Args(0)
End Sub

Public Sub CmdMotd(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'written by w00t 31/07/2004, updated for the spiffy cmdparser 1/08/2004
    '(see, I do contribute!)
    
    'NEW COOL MOTD STUFF!
    'The following sends the services MOTD, should probably be un-w00ted by aquanight.
    'Yes, I can think of a million config options related to this. A few:
    'UseMOTDOnConnect: Do we send services motd on connect?
    'UseMOTD: Do we reply to MOTD at all?
    'The actual MOTD could also be hardcoded, or partially hardcoded (ie "running winse")
    'Uh, that's about it. Enjoy the latest w00tCode(tm) :) --w00t
    
    'Did you know Unreal has SVSMOTD? Meaning we could make the services MOTD part of the Unreal
    'MOTD at startup? :) -aquanight
    Dim MOTDLine As String
    Dim sNick As String
    Dim i As Integer, u As User
    Dim j As Integer
    
    sNick = ExtractNickFromNUH(Source)
    
    Set u = Users(sNick)
    
    'this check should probably be moved to startup or something.
    j = FreeFile
    Call basFunctions.LogEvent(basMain.LogTypeDebug, "MOTD: Checking existance")
    Open App.Path & "\services.motd" For Append As #j
    Close #j
    
    Open App.Path & "\services.motd" For Input As #j
        If LOF(j) = 0 Then
            'doesnt exist yay
            Call basFunctions.LogEvent(basMain.LogTypeDebug, "MOTD: Doesn't exist.")
            basFunctions.SendData (":" & basMain.Config.ServerName & " 425 " & sNick & " :Services MOTD file is missing")
        Else
            Call basFunctions.LogEvent(basMain.LogTypeDebug, "MOTD: Does exist, sending.")
            'Just in case lame mIRC/other clients think the random MOTD is from the server it is connected
            'to:
            basFunctions.Notice basMain.Config.ServerName, Users(i).Nick, "*** - Message of the day, " + basMain.Config.ServerName
            basFunctions.SendData (":" & basMain.Config.ServerName & " 375 " & basMain.Users(i).Nick & " :- " & basMain.Config.ServerName & " Message of the Day")
            Do While Not EOF(j)
                'This should really be cached, and refreshed on rehash, but I'll leave such things
                'for when aqua unw00ts this :) Hey, at least I'm coding something...
                Line Input #j, MOTDLine
                'make our nice cool stuff :P go replace!
                MOTDLine = Replace(MOTDLine, "%WINSEVER", basMain.AppVersion)
                basFunctions.SendData (":" & basMain.Config.ServerName & " 372 " & basMain.Users(i).Nick & " :- " & MOTDLine)
                DoEvents 'lala, I'm naughty :P
            Loop
            basFunctions.SendData (":" & basMain.Config.ServerName & " 376 " & basMain.Users(i).Nick & " :End of /MOTD command.")
            Call basFunctions.LogEvent(basMain.LogTypeDebug, "MOTD: Finished sending.")
        End If
    Close #j
    'END NEW COOL MOTD STUFF
End Sub

Public Sub CmdVersion(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'Simple VERSION reply :)
    Dim sNick As String
    Dim i As Integer, u As Users

    sNick = ExtractNickFromNUH(Source)
    Set u = Users(sNick)
    Call basFunctions.SendData(":" & basMain.Config.ServerName & " 351 " & sNick & " " & basMain.AppName & "[" & basMain.AppVersion & "] " & basMain.Config.ServerName & " " & basMain.AppCompileInfo & " " & basMain.AppCompileDate)
End Sub

Public Sub CmdAdmin(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'ADMIN reply...
    Dim sNick As String
    sNick = ExtractNickFromNUH(Source)
    Call basFunctions.SendData(":" & basMain.Config.ServerName & " 256 " & sNick & " " & basMain.Config.ServerName & " :Administrative info")
    'First Line: Name and Info of the server
    Call basFunctions.SendData(":" & basMain.Config.ServerName & " 257 " & sNick & " :" & basMain.Config.ServerName & " " & basMain.Config.ServerDescription)
    'Second Line: The permenant Services Master (and email?)
    Call basFunctions.SendData(":" & basMain.Config.ServerName & " 258 " & sNick & " :" & basMain.Config.ServicesMaster)
    'Third Line: List of online service ops (nick only). Put comasters in bold, and master in bold and underline.
    Dim sSOPs As String, u As User
    For Each u In Users
        If u.Access <> "" Then
            If u.HasFlag(AccFlagMaster) Then 'I need to be anal about casematching here :) .
                sSOPs = sSOPs & MakeBold(MakeUnderline(u.Nick)) & " "
            ElseIf u.HasFlag(AccFlagCoMaster) Then
                sSOPs = sSOPs & MakeBold(u.Nick) & " "
            Else
                sSOPs = sSOPs & u.Nick & " "
            End If
        End If
    Next u
    sSOPs = RTrim(sSOPs)
    'We need to check this, to be sure we don't go over 510 bytes :/
    Dim sSendString As String
    sSendString = ":" & basMain.Config.ServerName & " 259 " & sNick & " :Online Operators: " & sSOPs
    If Len(sSendString) > 510 Then
        'Oh dear, we have that many operators (and/or their nicks are that long?).
        sSendString = ":" & basMain.Config.ServerName & " 259 " & sNick & " :Online Operators: " & MakeBold(MakeColor("A LOT", 4)) & " - Try " & MakeBold("/stats o " & basMain.Config.ServerName) & " to see them."
    End If
    Call basFunctions.SendData(sSendString)
End Sub

Public Sub CmdRehash(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'stub
End Sub

Public Sub CmdProtoctl(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'stub
End Sub

Public Sub CmdPass(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'stub
End Sub

Public Sub CmdServer(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    'stub
End Sub

Public Sub CmdNetinfo(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
'Format of this is:
':server NETINFO <maxglobal> <TS of EOS> <unreal proto> <cloak hash> 0 0 0 :<network name>
'For now, we'll just send exactly what they sent us :) .
    Call basFunctions.SendData(":" + basMain.Config.ServerName & " NETINFO " & Mid(RawCmd, InStr(RawCmd, "NETINFO ") + 8))
End Sub
