Attribute VB_Name = "basFunctions"
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

Public Declare Function ShellExecuteA Lib "shell32" (ByVal hWnd As Long, ByVal lpOperation As String, ByVal lpFile As String, ByVal lpParameters As String, ByVal lpDirectory As String, ByVal nShowCmd As Long) As Long
Public Const SW_SHOWMAXIMIZED = 3

Public Function ParseBuffer(ByVal Buffer As String) As Variant
    'Splits a sentance or whatever into an array of words.
    ParseBuffer = Split(Buffer, " ")
End Function

Public Sub LogEvent(ByVal Header As String, ByVal Message As String)
    'Logs given event to file.
    'Header eg "BUG"
    'Message eg "basMisc.Ident given null Username var."
    
    'check to log at all ;)
    If basMain.LoggingType = "NONE" Then
        Exit Sub
    End If
    'make sure we ignore debug messages unless we have debug logging ;)
    If basMain.LoggingType <> "DEBUG" And Header = "DEBUG" Then
        Exit Sub
    End If
    Open App.Path & "\winse.log" For Append As #FreeFile
    'we really should Format() Now, so it's consistent in the logfile. But meh. --w00t
    Print #FreeFile - 1, Now & "-[" & Header & "]: " & Message
    Close #FreeFile - 1
End Sub

Public Sub LogEventWithMessage(ByVal Header As String, ByVal Message As String)
Attribute LogEventWithMessage.VB_UserMemId = 0
    'Notifies all users with saccess, and logs event to file
    Call basFunctions.NotifyAllUsersWithServicesAccess(Header & " " & Message)
    Call basFunctions.LogEvent(Header, Message)
End Sub

Public Function IsChanRegistered(ByVal ChanName As String) As Boolean
    Dim Password As String
    'If we have a password, we must be registered ;)
    On Error Resume Next
    Password = sChanServ.DB(ChanName)("Password")
    IsChanRegistered = (Password <> "")
End Function

Public Function IsNickRegistered(ByVal NickName As String)
    Dim Password As String
    'If we have a password, we must be registered ;)
    Password = basFileIO.GetInitEntry(App.Path & "\databases\users.db", UCase(NickName), "Password")
    IsNickRegistered = (Password <> "")
End Function

Public Sub IntroduceClient(ByVal Nick As String, ByVal Host As String, ByVal Name As String, Optional ByVal IsBot As Boolean = False, Optional ByVal ExtraModes As String = "")
    'stop erroring if the link died.
    On Error Resume Next
    Dim MyTime As String
    MyTime = basUnixTime.GetTime
    'we directly send the nick and user commands, as buffering stuffs things up. --w00t
    basFunctions.PutQuick "NICK " & Nick & " 1 " & MyTime & " " & Name & " " & Host & " " & basMain.Config.ServerName & " " & Nick & vbCrLf
    basFunctions.PutQuick "USER " & Nick & " " & Name & " " & basMain.Config.ServerName & " " & Name & vbCrLf
    basFunctions.SendData ":" & Nick & " MODE " & Nick & " +qS"
    If Not IsBot Then basFunctions.SendData ":" & Nick & " MODE " & Nick & " +d"
    If ExtraModes <> "" Then basFunctions.SendData ":" & Nick & " MODE " & Nick & " +" & ExtraModes
End Sub

Public Sub JoinServicesToChannel(ByVal Sender As Integer, ByVal channel As String)
    'This may need to be bumped to a larger
    'type to satisify Option Strict when we .NET-ize it :) --aquanight
    Dim i As Byte
    Dim Nick, Host, Name As String
    For i = 0 To basMain.TotalServices - 1
        Nick = basMain.Service(i).Nick
        Host = basMain.Service(i).Hostmask
        Name = basMain.Service(i).Name
        Call basFunctions.SendData(":" & Nick & " JOIN " & channel)
        basFunctions.SendData ":" & Nick & " MODE " & channel & " +ao " & Nick & " " & Nick
    Next i
End Sub

Public Sub PartServicesFromChannel(ByVal Sender As Integer, ByVal channel As String)
    'See JoinServicesToChannel comment on this.  - aquanight
    Dim i As Byte
    Dim Nick, Host, Name As String
    For i = 0 To basMain.TotalServices - 1
        Nick = basMain.Service(i).Nick
        Host = basMain.Service(i).Hostmask
        Name = basMain.Service(i).Name
        Call basFunctions.SendData(":" & Nick & " PART " & channel)
    Next i
End Sub

Public Function FormatString(ByVal s As String, ParamArray Args() As Variant)
    'Replaces format specifiers in s with the arguments formatted accordingly.
    'Format specifiers take the following form:
    '{index[,minwidth][:format]} where format goes to VB's own Format() function.
    'minwidth may be negative for a right alignment.
    Dim iPos As Integer
    Dim nIndex As Integer, nWidth As Integer, sFormat As String
    Dim sIndexTemp As String, sWidthTemp As String
    Dim cState As String * 1 'Current state: " " normal, "{" reading index, "," reading width, ":" reading format
    Dim sTmp As String
    Dim ch As String * 1
    cState = " "
    For iPos = 1 To Len(s)
        ch = Mid(s, iPos, 1)
        Select Case cState
            Case " " 'Normal
                If ch = "{" Then
                    If Mid(s, iPos + 1, 1) = "{" Then
                        iPos = iPos + 1
                        sTmp = sTmp & "{"
                    Else
                        cState = "{"
                    End If
                Else
                    sTmp = sTmp & ch
                End If
            Case "{" 'Index
                Select Case ch
                    Case ",", ":"
                        cState = ch
                        On Error GoTo BadFormat
                        nIndex = CInt(sIndexTemp)
                        On Error GoTo 0
                    Case "}"
                        On Error GoTo BadFormat
                        nIndex = CInt(sIndexTemp)
                        On Error GoTo 0
                        'I hate having to do this, but one copy of code > than several.
                        GoSub DoFormat 'This will clear out the temps and everything.
                        cState = " "
                    Case Else
                        sIndexTemp = sIndexTemp & ch
                    'End Case
                End Select
            Case "," 'Width
                Select Case ch
                    Case ":"
                        cState = ch
                        On Error GoTo BadFormat
                        nWidth = CInt(sWidthTemp)
                    Case "}"
                        On Error GoTo BadFormat
                        nWidth = CInt(sWidthTemp)
                        On Error GoTo 0
                        'I hate having to do this, but one copy of code > than several.
                        GoSub DoFormat 'This will clear out the temps and everything.
                        cState = " "
                    Case Else
                        sWidthTemp = sWidthTemp & ch
                    'End Case
                End Select
            Case ":" 'Format
                If ch = "}" Then
                    If Mid(s, iPos + 1, 1) = "}" Then
                        sFormat = sFormat & "}"
                        iPos = iPos + 1
                    Else
                        On Error GoTo BadFormat
                        nIndex = CInt(sIndexTemp)
                        On Error GoTo 0
                        'I hate having to do this, but one copy of code > than several.
                        GoSub DoFormat 'This will clear out the temps and everything.
                        cState = " "
                    End If
                Else
                    sFormat = sFormat & ch
                End If
            'End Case
        End Select
    Next iPos
    FormatString = sTmp
    Exit Function
DoFormat:
    On Error GoTo BadFormat
    Dim v As Variant, sWork As String
    v = Args(nIndex)
    If sFormat = "" Then sWork = CStr(v) Else sWork = Format(v, sFormat)
    Select Case nWidth
        Case Is < 0 'Right align.
            If Len(sWork) < Abs(nWidth) Then sWork = String(Abs(Len(sWork) - Abs(nWidth)), 32) & sWork
        Case Is > 0 'Left align.
            If Len(sWork) < Abs(nWidth) Then sWork = sWork & String(Abs(Len(sWork) - Abs(nWidth)), 32)
        'End Case
    End Select
    sTmp = sTmp & sWork
    sIndexTemp = ""
    sWidthTemp = ""
    sFormat = ""
    nIndex = 0
    nWidth = 0
    sWork = ""
    v = Empty
    Return
BadFormat:
    Err.Raise 5, , "Format error"
End Function

Public Sub SendData(ByVal Buffer As String)
    'With the new socket library, buffering might not
    'be needed anymore, but for now I think it's ok to
    'leave alone - aquanight
    basMain.Buffer(basMain.BufferElements) = Buffer & vbCrLf
    basMain.BufferElements = basMain.BufferElements + 1
End Sub

Public Sub PutQuick(ByVal Buffer As String)
    'For putting important messages that can't wait,
    'like PONGs. In other words - this doesn't buffer!
    frmServer.tcpServer.Send Buffer
End Sub

Public Sub PrivMsg(ByVal Sender As String, ByVal Reciever As String, ByVal Message As String)
    basFunctions.SendData (":" & Sender & " PRIVMSG " & Reciever & " :" & Message)
End Sub

Public Sub Notice(ByVal Sender As String, ByVal Reciever As String, ByVal Message As String)
    basFunctions.SendData (":" & Sender & " NOTICE " & Reciever & " :" & Message)
End Sub

Public Sub SendMessage(ByVal Sender As String, ByVal Reciever As String, ByVal Message As String)
    Dim UserID As Integer
    'Wrapper for notice\privmsg. Checks which we should use, and uses it.
    On Error GoTo ForgetIt
    Select Case Users(Reciever).MsgStyle
        Case True
            'Notice
            Call basFunctions.Notice(Sender, Reciever, Message)
        Case False
            'msg
            Call basFunctions.PrivMsg(Sender, Reciever, Message)
    End Select
ForgetIt:
    Exit Sub
End Sub

'Sender is ALWAYS the server!
Public Sub SendNumeric(ByVal Receiver As String, ByVal Numeric As Integer, ByVal Message As String)
    SendData ":" + basMain.Config.ServerName + " " + Format(Numeric, "000") + " " + Receiver + " " + Message
End Sub

Public Sub GlobalMessage(ByVal Message As String)
    'I'm thinking that we should Global the easy way :)
    'IMHO, global messages should always be NOTICE,
    'but that's partly because mIRC does wierd things
    'with $target PRIVMSGs (in status: (nick) message).
    ' - aquanight
    basFunctions.SendData ":" + Service(SVSINDEX_GLOBAL).Nick + " NOTICE " + basMain.Config.GlobalTargets + " :" + Message
End Sub

Public Sub WallOps(ByVal Sender As String, ByVal Message As String)
    If Sender = "" Then Sender = basMain.Config.ServerName
    SendData ":" + Sender + " GLOBOPS :" + Message
End Sub

Public Sub SquitServices(Optional ByVal Message As String = "")
    Call basFunctions.SendData("SQUIT " & basMain.Config.UplinkName & IIf(Message <> "", " :" & Message, ""))
    'Now flush all remaining data...
    On Error Resume Next
    Dim i As Integer
    For i = 0 To basMain.BufferElements
        DoEvents
        DoEvents
        If basMain.Buffer(i) <> "" Then Call frmServer.tcpServer.Send(basMain.Buffer(i))
        DoEvents
        DoEvents
        basMain.Buffer(i) = ""
    Next
    basMain.BufferElements = 0
    frmServer.tcpServer.Shutdown 2
    frmServer.tcpServer.Close
End Sub

Public Sub DelServer(ByVal Name As String, Optional ByVal Message As String = "")
    Call basFunctions.SendData("SQUIT " & Name & " :" & IIf(Message <> "", " :" & Message, ""))
End Sub

Public Sub AddServer(ByVal Name As String, Optional ByVal Message As String = "Winse JUPE")
    Call basFunctions.SendData("SERVER " & Name & " 1 :" & " " & Message & vbCrLf)
End Sub

Public Sub NotifyAllUsersWithServicesAccess(ByVal Message As String)
    Call NotifyAllUsersWithFlags(AccFlagGetServNotices, Message)
End Sub

Public Sub NotifyAllUsersWithFlags(ByVal Flag As String, ByVal Message As String)
    Dim i As Integer
    Dim Reciever As String
    Dim Sender As String
    Sender = Service(SVSINDEX_GLOBAL).Nick
    For i = 1 To Users.Count
        If basMain.Users(i).HasFlag(Flag) Then
            Reciever = basMain.Users(i).Nick
            Call basFunctions.SendMessage(Sender, Reciever, "Services Notice: " & Message)
        End If
    Next i
End Sub

Public Sub RaiseCustomEvent(ByVal Source As String, ByVal EventName As String, ParamArray Parameters() As Variant)
    'Calls handlers formatted like this:
    'Public Sub HandleEvent(ByVal Source As String, ByVal EventName As String, Parameters() As Variant)
    sAdminServ.HandleEvent Source, EventName, Parameters
    sAgent.HandleEvent Source, EventName, Parameters
    sChanServ.HandleEvent Source, EventName, Parameters
    sDebugServ.HandleEvent Source, EventName, Parameters
    sMassServ.HandleEvent Source, EventName, Parameters
    sNickServ.HandleEvent Source, EventName, Parameters
    sOperServ.HandleEvent Source, EventName, Parameters
    sRootServ.HandleEvent Source, EventName, Parameters
End Sub

Public Sub ParseCmd(ByVal Incoming As String)
    If Incoming = "" Then Exit Sub
    Dim sTmp As String
    sTmp = Incoming 'Make a copy of the incoming text.
    'Hopefully this will replace all the stuff in
    '*_DataArrival :P . I'm hoping this will make us
    'less dependent on the form.
    Dim sLongArg As String 'Contain the long argument.
    Dim sSource As String 'Contain the source.
    Dim sCmd As String 'The command
    Dim vArgs As Variant 'Args not part of the long arg.
    'Asc() returns the ASCII code of the first char
    'of a string, so we can use that to check for a
    'source :) .
    If Asc(sTmp) = Asc(":") Then
        sSource = Mid(sTmp, 2)
        sSource = Left(sSource, InStr(sSource, " ") - 1)
        sTmp = Mid(sTmp, InStr(sTmp, " ") + 1)
    End If
    'Now pull the command.
    If sTmp = "" Then Exit Sub
    If InStr(sTmp, " ") = 0 Then
        sCmd = sTmp
        sTmp = ""
    Else
        sCmd = Left(sTmp, InStr(sTmp, " ") - 1)
        sTmp = Mid(sTmp, InStr(sTmp, " ") + 1)
    End If
    'Now, do we have any arguments?
    If sTmp <> "" Then
        'Pull the long argument.
        If Asc(sTmp) = Asc(":") Then
            'The whole list is the long arg.
            sLongArg = Mid(sTmp, 2)
            sTmp = ""
        ElseIf InStr(sTmp, " :") > 0 Then
            'The long arg comes later.
            sLongArg = Mid(sTmp, InStr(sTmp, " :") + 2)
            sTmp = Left(sTmp, InStr(sTmp, " :") - 1)
        End If
        'Now parse the remaining arguments.
        If sTmp <> "" Then
            vArgs = Split(sTmp, " ")
            'If we have a long arg, append it to the
            'end.
            ReDim Preserve vArgs(UBound(vArgs) + 1)
            vArgs(UBound(vArgs)) = sLongArg
        Else
            ReDim vArgs(0)
            vArgs(0) = sLongArg
        End If
    End If
    'Now we have the command parsed. Let's see what to
    'do with it!
    'Create a command dispatcher. FIXME: Maybe we should
    'have this be a persistant variable?
    Dim cd As CommandDispatcher
    Set cd = New CommandDispatcher
    'Now execute it :) Use late-binding to pick the
    'correct procedure.
    Dim sArgs() As String, idx As Long
    If Not IsEmpty(vArgs) Then
        ReDim sArgs(LBound(vArgs) To UBound(vArgs))
        For idx = LBound(vArgs) To UBound(vArgs)
            sArgs(idx) = vArgs(idx)
        Next idx
    End If
    'Now do a source check. If it's not a server, and we don't know it, remove it.
    If sSource <> "" And InStr(sSource, ".") = 0 Then
        'It's a user.
        If Not Users.Exists(sSource) Then
            'Could we be introducing a user (strange IRCd puts the new nick in the source param)?
            If sCmd <> "NICK" Or UBound(sArgs) <= 2 Then
                'Not introducing and doesn't exist. This is bad.
                LogEventWithMessage LogTypeError, "EEEK! Unknown user " & sSource & ". Are we desynched?"
                SendData ":" & basMain.Config.ServerName & " KILL " & sSource & " :" & basMain.Config.ServerName & " (" & sSource & "(?) <- " & basMain.Config.UplinkName & ")"
                Exit Sub
            'Otherwise, it's an IRCd introducing a user and putting the new nick in the source.
            End If
        'Otherwise it's a server.
        End If
    'Otherwise it's a server (specifically the one we are linked to).
    End If
    'Supposedly this won't catch errors in a called
    'procedure...
    'I hope so...
    On Local Error Resume Next
    'To add support for a command, create a sub in
    'CommandDispatcher, using the format Cmd<cmdname>.
    'See CommandDispatcher.cls for more info.
    Call CallByName(cd, "Cmd" + sCmd, VbMethod, sSource, sArgs, Incoming)
    If Err.Number <> 0 Then
        'Debug.Print Err.Number, Err.Description
        'FOR GODS SAKE... LOGGING!!! --w00t
        Call basFunctions.LogEvent(basMain.LogTypeDebug, "ParseCmd: " & Incoming)
        Call basFunctions.LogEvent(basMain.LogTypeError, "ParseCmd: " & Err.Number & " " & Err.Description)
        Exit Sub
    End If
    'OK so now we need to send it on it's merry way to
    'the service modules... hm
    'NOTE: These could theoretically handle PRIVMSG,
    'NOTICE and MODE, but that isn't really a good idea
    'as we have seperate subs for those purposes ;p .
    sAdminServ.HandleCommand sSource, sCmd, sArgs
    sAgent.HandleCommand sSource, sCmd, sArgs
    sChanServ.HandleCommand sSource, sCmd, sArgs
    sDebugServ.HandleCommand sSource, sCmd, sArgs
    sMassServ.HandleCommand sSource, sCmd, sArgs
    sNickServ.HandleCommand sSource, sCmd, sArgs
    sOperServ.HandleCommand sSource, sCmd, sArgs
    sRootServ.HandleCommand sSource, sCmd, sArgs
End Sub

Public Function CountArray(ByRef WhatArray As Variant) As Long
    If Not IsArray(WhatArray) Then Error 5
    Dim lRet As Long
    On Error Resume Next
    lRet = UBound(WhatArray) - LBound(WhatArray) + 1
    'If errored, lRet will remain 0.
    CountArray = lRet
End Function

'Sometimes we have to modify an item in a collection.
'Unfortunately, VB6's collection does not allow us to
'simply assign a new value into the collection, so we
'are going to use a pretty ugly work around. Property
'Let|Set allows us to use the assignment syntax to
'call these, so use:
'[Let|Set] SetItem(<col>, <index>) = <newval>
'NOTE: Due to the nature of this hack, if you use an
'integer index, any string key WILL be lost! If you use
'a key value, the numeric position of the item will no
'longer be correct! - aquanight
Public Property Let SetItem(ByVal Collection As Collection, ByVal Index As Variant, ByVal NewValue As Variant)
    Collection.Remove Index
    If VarType(Index) = vbString Then
        Collection.Add NewValue, Key:=Index
    Else
        Collection.Add NewValue, before:=Index
    End If
End Property

Public Property Set SetItem(ByVal Collection As Collection, ByVal Index As Variant, ByVal NewValue As Object)
    Collection.Remove Index
    If VarType(Index) = vbString Then
        Collection.Add NewValue, Key:=Index
    Else
        Collection.Add NewValue, before:=Index
    End If
End Property

'Something to tell us if a collection item exists.
Public Function CollectionContains(ByVal Collection As Collection, ByVal Key As String) As Boolean
    On Error GoTo Nope
    Call Collection.Item(Key)
    CollectionContains = True
    Exit Function
Nope:
    CollectionContains = False
End Function

'The reason all the Dispatch* procs force a restart is
'because they should NEVER be called with illegal
'arguments. Why?
'ChanID < 0 is alredy checked before entry, and the
'presence of arguments are checked as well. A skipped
'argument could possibly cause things to go pear-shaped,
'but I can't see that happening with a serious IRCd.
'Only if we had some form of INJECT command, and in that
'case it's the user's fault :P .

Public Sub RestartServices(Optional ByVal RestartMsg As String = "Restarting...")
    'Restart the service daemon completely. OperServ
    'RESTART? Forced restarts due to sanity checks?
    'You tell me.
    NotifyAllUsersWithServicesAccess "Restarting services... Reason: " & RestartMsg
    SquitServices RestartMsg
    Shell App.Path & "\" & App.EXEName & ".exe", vbMinimizedNoFocus
    End 'Splat.
End Sub

'PHEW! :> -aquanight
'Yes, I really should split this into other .bas files, but I cba. And hey,
'is it worth it? --w00t

'Returns True if the passed nick is a Services Nickname.
Public Function IsServicesNick(ByVal Nick As String) As Boolean
    Dim i As Long
    For i = 0 To basMain.TotalServices - 1
        If Nick = basMain.Service(i).Nick Then
            IsServicesNick = True
            Exit Function
        End If
    Next i
    IsServicesNick = False
End Function

Public Function ExtractNickFromNUH(ByVal Prefix As String) As String
    If InStr(Prefix, "!") = 0 Then
        If InStr(Prefix, "@") = 0 Then
            ExtractNickFromNUH = Prefix
        Else
            ExtractNickFromNUH = Left(Prefix, InStr(Prefix, "@") - 1)
        End If
    Else
        ExtractNickFromNUH = Left(Prefix, InStr(Prefix, "!") - 1)
    End If
End Function

Public Sub CommandHelp(ByVal Sender As User, Args() As String, ServicesHelpFileDir As String, ServicesID As Integer)
    'Contains w00tSuperDuperHelpSystem v1.1 :D

    'Basically, this grabs text from an external helpfile and sends it to the user.
    'ServicesHelpFileDir MUST exist! REALLY!
    Dim SenderNick As String
    Dim f As String
    Dim HelpLine As String
    Dim i As Integer
    Dim j As Integer

    SenderNick = Sender.Nick
    f = App.Path & "\help\" & ServicesHelpFileDir
    If UBound(Args) = 1 Then
        f = f & "\" & LCase(Args(1))
    ElseIf UBound(Args) > 1 Then
        For i = 1 To UBound(Args)
            f = f & "\" & LCase(Args(i))
        Next i
    Else
        f = f & "\index"
    End If

    j = FreeFile
    On Error GoTo ErrNeedIndex
        Open f For Append As #j
    On Error GoTo 0
    Close #j
    Open f For Input As #j
        If LOF(j) = 0 Then
            Call basFunctions.SendMessage(basMain.Service(ServicesID).Nick, SenderNick, Replies.UnknownCommandOrHelpNotAvailable)
            Call basFunctions.LogEvent(basMain.LogTypeDebug, "CommandHelp: Missing Helpfile(?): " & f)
            Close #j
            Kill f
            Exit Sub
        End If
        Do While Not EOF(j)
            Line Input #j, HelpLine
            Call basFunctions.SendMessage(basMain.Service(ServicesID).Nick, SenderNick, HelpLine)
        Loop
    Close #j
    Exit Sub
ErrNeedIndex:
    f = f & "\index"
    Resume
End Sub

Public Function StringRepeat(ByVal Str As String, ByVal Count As Long)
    Dim sWork As String
    For Count = Count To 1 Step -1
        sWork = sWork & Str
    Next Count
    StringRepeat = sWork
End Function

'These do simple mIRC format code conversions:
'%a <-> CTCP
'%b <-> Bold
'%c <-> Color
'%_ <-> Underline
'%v <-> Reverse
'%o <-> Plain
'Case doesn't matter.
Public Function EscapeMIRCFormatting(ByVal Text As String) As String
    Dim sWork As String
    sWork = Text
    sWork = Replace(sWork, MIRC_CTCP, "%A", , , vbBinaryCompare)
    sWork = Replace(sWork, MIRC_BOLD, "%B", , , vbBinaryCompare)
    sWork = Replace(sWork, MIRC_COLOR, "%C", , , vbBinaryCompare)
    sWork = Replace(sWork, MIRC_UNDERLINE, "%_", , , vbBinaryCompare)
    sWork = Replace(sWork, MIRC_REVERSE, "%V", , , vbBinaryCompare)
    sWork = Replace(sWork, MIRC_PLAIN, "%O", , , vbBinaryCompare)
End Function

Public Function UnescapeMIRCFOrmatting(ByVal Text As String) As String
    Dim sWork As String
    sWork = Text
    sWork = Replace(sWork, "%A", MIRC_CTCP, , , vbTextCompare)
    sWork = Replace(sWork, "%B", MIRC_BOLD, , , vbTextCompare)
    sWork = Replace(sWork, "%C", MIRC_COLOR, , , vbTextCompare)
    sWork = Replace(sWork, "%_", MIRC_UNDERLINE, , , vbTextCompare)
    sWork = Replace(sWork, "%V", MIRC_REVERSE, , , vbTextCompare)
    sWork = Replace(sWork, "%O", MIRC_PLAIN, , , vbTextCompare)
End Function

Public Function MakeBold(ByVal Text As String) As String
    MakeBold = MIRC_BOLD & Text & MIRC_BOLD
End Function

Public Function MakeUnderline(ByVal Text As String) As String
    MakeUnderline = MIRC_UNDERLINE & Text & MIRC_UNDERLINE
End Function

Public Function MakeReverse(ByVal Text As String) As String
    MakeReverse = MIRC_REVERSE & Text & MIRC_REVERSE
End Function

Public Function MakeColor(ByVal Text As String, Optional ByVal FGColor As Byte = 0, Optional ByVal BGCOlor As Byte = 255)
    MakeColor = MIRC_COLOR & CStr(FGColor) & IIf(BGCOlor <= 15, "," & CStr(BGCOlor), "") & Text & MIRC_COLOR
End Function

Public Function MakeCTCP(ByVal Text As String)
    MakeCTCP = MIRC_CTCP & Text & MIRC_CTCP
End Function

Public Function NUHMaskIsMatch(ByVal User As User, ByVal Mask As String) As Boolean
    Dim sMask As String
    sMask = Mask
    '# and [ need to be "unspecialed" here.
    sMask = Replace(sMask, "[", "[[]")
    sMask = Replace(sMask, "#", "[#]")
    NUHMaskIsMatch = (User.Nick & "!" & User.UserName & "@" & User.HostName Like Mask)
End Function

Public Function CollToArray(ByVal col As Collection, Optional ByRef Keys As Variant) As Variant
    'Keys can be anything we can enumerate.
    Dim idx As Long, vRes() As String
    If IsMissing(Keys) Then
        ReDim vRes(0 To col.Count - 1)
        For idx = 0 To col.Count - 1
            vRes(idx) = col(idx + 1)
        Next idx
    ElseIf VarType(Keys) = (vbArray Or vbString) Then
        ReDim vRes(0 To UBound(Keys))
        For idx = 0 To UBound(Keys)
            vRes(idx) = col(Keys(idx))
        Next idx
    ElseIf IsObject(Keys) Then
        If TypeOf Keys Is Collection Then
            For idx = 0 To Keys.Count - 1
                vRes(idx) = col(Keys(idx + 1))
            Next idx
        Else: Error 13
        End If
    Else: Error 13
    End If
End Function
