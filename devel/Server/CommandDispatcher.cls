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
        Dim iNick As Integer
        iNick = FreeUserID
        'Now check for a collision.
        If basFunctions.IsServicesNick(Args(0)) Then
            'COLLISION!!!!!!!!
            'For services nicks, we ALWAYS win.
            basFunctions.PutQuick ":" + basMain.Config.ServerName + " KILL " + Args(0) + " :" + basMain.Config.ServerName + " (Nick Collision (" + basMain.Config.UplinkName + " <- " + basMain.Config.ServerName + "))"
            'Send out a warning...
            Call basFunctions.LogEventWithMessage(basMain.LogTypeWarn, Replies.SanityCheckServicesNickInUse + Args(0) + "!" + Args(2) + "@" + Args(3))
            Exit Sub
        ElseIf ReturnUserIndex(Args(0)) >= 0 Then
            'COLLISION!!!!!!!!
            'Now a real server would do a Timestamp
            'check and remove the one with a more
            'recent stamp, but as we have no directly
            'connect users, and only one server, we
            'simply allow it - the IRCd wins.
            '(so theoretically, if we get here, we're fucked.)
            iNick = basFunctions.ReturnUserIndex(Args(0))
            'Send out a warning...
            Call basFunctions.LogEventWithMessage(basMain.LogTypeWarn, "Collision: " + Args(0) + "!" + Args(2) + "@" + Args(3))
            'Overwrite the remaining fields.
        End If
        With basMain.Users(iNick)
            .Nick = Args(0)
            .SignOn = Args(2)
            .UserName = Args(3)
            .HostName = Args(4)
            .Server = Args(5)
            .RealName = Args(7)
            'Initialize the remaining fields.
            .AbuseTeam = False
            .Access = 0
            Set .Channels = New Collection
            Set .Custom = New Collection
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
        basMain.TotalUsers = basMain.TotalUsers + 1
        'send the MOTD, DADAA!!! --w00t
        Dim Temp As New CommandDispatcher
        Call Temp.CmdMotd(Args(0), Args(), RawCmd)
        Set Temp = Nothing
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
            'Send out a warning...
            Call basFunctions.LogEventWithMessage(basMain.LogTypeWarn, Replies.SanityCheckServicesNickInUse + Args(0) + "!" + Args(2) + "@" + Args(3))
            Exit Sub
        ElseIf ReturnUserIndex(Args(0)) >= 0 Then
            'COLLISION!!!!!!!!
            'This is s nickchange... so all I can say
            'is... WTF?
            Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " KILL " + Args(0) + " :" + basMain.Config.ServerName + " (Nick Collision (" + basMain.Config.UplinkName + " <- " + basMain.Config.ServerName + "))")
            'Send out a warning...
            Call basFunctions.LogEventWithMessage(basMain.LogTypeWarn, Replies.SanityCheckNickChangeCollision + Args(0) + "!" + Args(2) + "@" + Args(3))
            'Overwrite the remaining fields.
            Exit Sub
        End If
        'Otherwise, we're ok.
        Users(ReturnUserIndex(ExtractNickFromNUH(Source))).Nick = Args(0)
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
    'First send out the PRIVMSG.
    Select Case UCase(ExtractNickFromNUH(Args(0)))
        Case "NICKSERV"
            sNickServ.NickservHandler Args(1), ReturnUserIndex(sNick)
        Case "CHANSERV"
            sChanServ.ChanservHandler Args(1), ReturnUserIndex(sNick)
        Case "MEMOSERV"
            sMemoServ.MemoservHandler Args(1), ReturnUserIndex(sNick)
        Case "OPERSERV"
            sOperServ.OperservHandler Args(1), ReturnUserIndex(sNick)
        Case "BOTSERV"
            sBotServ.BotservHandler Args(1), ReturnUserIndex(sNick)
        Case "AGENT"
            sAgent.AgentHandler Args(1), ReturnUserIndex(sNick)
        Case "ADMINSERV"
            sAdminServ.AdminservHandler Args(1), ReturnUserIndex(sNick)
        Case "DEBUGSERV"
            sDebugServ.DebugservHandler Args(1), ReturnUserIndex(sNick)
        Case "HOSTSERV"
            sHostServ.HostservHandler Args(1), ReturnUserIndex(sNick)
        Case "MASSERV"
            sMassServ.MassservHandler Args(1), ReturnUserIndex(sNick)
        Case "ROOTSERV"
            sRootServ.RootservHandler Args(1), ReturnUserIndex(sNick)
        Case Else 'Bot/Channel?
    End Select
    'Now do flood crap.
    Call CheckFloodLevel(ReturnUserIndex(sNick))
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
    If ReturnUserIndex(ExtractNickFromNUH(Args(0))) >= 0 Then
        Dim i As Integer
        i = ReturnUserIndex(ExtractNickFromNUH(Args(0)))
        'Let admins know.
        Call LogEventWithMessage(basMain.LogTypeNotice, "KILL: " + Users(i).Nick + "!" + Users(i).UserName + "@" + Users(i).HostName + " from " + sNick + " Path: " + Args(1))
        'Remove it.
        Dim s(0) As String
        s(0) = "KILL " + Args(1)
        Call CmdQuit(Args(0), s, RawCmd)
    ElseIf IsServicesNick(ExtractNickFromNUH(Args(0))) Then
        'ARRRGH! BAD OPER! *SPANK*
        For i = 0 To basMain.TotalServices - 1
            If UCase(Args(0)) = UCase(basMain.Service(i).Nick) Then
                Call basFunctions.IntroduceClient(basMain.Service(i).Nick, basMain.Service(i).Hostmask, basMain.Service(i).Name)
            End If
        Next
        Call basFunctions.LogEventWithMessage(basMain.LogTypeNotice, Replace(Replies.UserKilledService, "%n", sNick))
        If Not bSrvKill Then Call KillUser(ReturnUserIndex(sNick), Replies.KillReasonKilledService)
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
    i = ReturnUserIndex(sNick)
    If i < 0 Then
        'WTF? *SPLAT*
        Call basFunctions.LogEventWithMessage(LogTypeError, Replies.SanityCheckLostUser)
        Exit Sub
    End If
    Users(i).Nick = ""
    Set Users(i).Channels = Nothing
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
    If ReturnUserIndex(Args(0)) >= 0 Then
        SetUserModes ReturnUserIndex(Args(0)), sModeString
    ElseIf ReturnChannelIndex(Args(0)) >= 0 Then
        SetChannelModes ReturnChannelIndex(Args(0)), sModeString
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
    Dim chns As Variant, i As Integer, v As Variant
    i = ReturnUserIndex(sNick)
    chns = Split(Args(0), ",")
    Dim sChan As Variant
    For Each sChan In chns
        If sChan = "0" Then
            For Each v In Users(i).Channels
                Dim s(0) As String
                s(0) = Channels(v).Name
                Call CmdPart(Source, s, RawCmd)
            Next v
        Else
            If ReturnChannelIndex(sChan) = -1 Then
                'NEW CHANNEL!
                With Channels(FreeChanID)
                    .Name = sChan
                    Set .Users = New Collection
                    Set .UsersModes = New Collection
                    .Users.Add i, CStr(i)
                    .UsersModes.Add "", CStr(i)
                    'Initialize the rest.
                    Erase .AccessList
                    Set .Bans = New Collection
                    .ChannelKey = ""
                    Set .Custom = New Collection
                    Set .Excepts = New Collection
                    .FloodProtection = ""
                    .FounderPassword = ""
                    Set .Invites = New Collection
                    .MLock = ""
                    .Modes = ""
                    .OverflowChannel = ""
                    .OverflowLimit = 0
                    .Topic = ""
                    .TopicSetBy = ""
                    .TopicSetOn = 0
                    .TotalChannelUsers = .Users.Count
                    .TotalUsersOnAccessList = 0
                End With
            Else
                With Channels(ReturnChannelIndex(sChan))
                    If Not CollectionContains(.Users, CStr(i)) Then
                        .Users.Add i, CStr(i)
                        .UsersModes.Add "", CStr(i)
                        .TotalChannelUsers = .TotalChannelUsers + 1
                    End If
                End With
            End If
            Users(i).Channels.Add ReturnChannelIndex(sChan), CStr(ReturnChannelIndex(sChan))
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
    Dim chns As Variant, i As Integer
    i = ReturnUserIndex(sNick)
    chns = Split(Args(0), ",")
    Dim sChan As Variant
    For Each sChan In chns
        Users(i).Channels.Remove CStr(ReturnChannelIndex(sChan))
        With Channels(ReturnChannelIndex(sChan))
            If CollectionContains(.Users, CStr(i)) Then
                .Users.Remove CStr(i)
                .UsersModes.Remove CStr(i)
                .TotalChannelUsers = .TotalChannelUsers - 1
            End If
            If .Users.Count = 0 Then
                'Invalidate the channel, as it is now
                'empty.
                .Name = ""
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
        With Channels(ReturnChannelIndex(Args(0)))
            .Topic = Args(1)
            .TopicSetBy = Source
            .TopicSetOn = basUnixTime.GetTime
        End With
    ElseIf UBound(Args) > 1 And UBound(Args) < 3 Then
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replies.SanityCheckTOPICInsufficientParameters)
        Call basFunctions.PutQuick(":" + basMain.Config.ServerName + " 461 " + basMain.Config.UplinkName + " TOPIC :Not enough parameters")
    ElseIf UBound(Args) >= 3 Then
        With Channels(ReturnChannelIndex(Args(0)))
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
    Dim i As Integer
    i = ReturnUserIndex(sNick)
    If UCase(Config.ServerType) = "UNREAL" Then
        Call SetUserModes(i, "+xt")
    Else
        'Are there other IRCds that do modechange with
        'SETHOST?
    End If
    Users(i).VirtHost = Args(0)
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
    Dim MOTDLine As String
    Dim sNick As String
    Dim i As Integer
    Dim j As Integer
    
    sNick = ExtractNickFromNUH(Source)
    
    i = basFunctions.ReturnUserIndex(sNick)
    
    'this check should probably be moved to startup or something.
    j = FreeFile
    Call basFunctions.LogEvent(basMain.LogTypeDebug, "MOTD: Checking existance")
    Open App.Path & "\services.motd" For Append As #j
    Close #j
    
    Open App.Path & "\services.motd" For Input As #j
        If LOF(j) = 0 Then
            'doesnt exist yay
            Call basFunctions.LogEvent(basMain.LogTypeDebug, "MOTD: Doesn't exist.")
            basFunctions.SendData (":" & basMain.Config.ServerName & " 425 " & basMain.Users(i).Nick & " :Services MOTD file is missing")
            Else
                Call basFunctions.LogEvent(basMain.LogTypeDebug, "MOTD: Does exist, sending.")
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
    Dim i As Integer

    sNick = ExtractNickFromNUH(Source)
    i = basFunctions.ReturnUserIndex(sNick)
    basFunctions.SendData (":" & basMain.Config.ServerName & " 351 " & basMain.Users(i).Nick & " " & basMain.AppName & "[" & basMain.AppVersion & "] " & basMain.Config.ServerName & " " & basMain.AppCompileInfo & " " & basMain.AppCompileDate)
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
    'stub
End Sub
