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
    Password = sChanServ.DB(sChanServ.DBIndexOf(ChanName)).Password
    IsChanRegistered = (Password <> "")
End Function

Public Function IsNickRegistered(ByVal NickName As String)
    Dim Password As String
    'If we have a password, we must be registered ;)
    Password = sNickServ.DB(sNickServ.DBIndexOf(NickName)).Password
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

Public Sub JoinServicesToChannel(ByVal Sender As Integer, ByVal Channel As String)
    'This may need to be bumped to a larger
    'type to satisify Option Strict when we .NET-ize it :) --aquanight
    Dim i As Byte
    Dim Nick, Host, Name As String
    For i = 0 To basMain.TotalServices - 1
        Nick = basMain.Service(i).Nick
        Host = basMain.Service(i).Hostmask
        Name = basMain.Service(i).Name
        Call basFunctions.SendData(":" & Nick & " JOIN " & Channel)
        basFunctions.SendData ":" & Nick & " MODE " & Channel & " +ao " & Nick & " " & Nick
    Next i
End Sub

Public Sub PartServicesFromChannel(ByVal Sender As Integer, ByVal Channel As String)
    'See JoinServicesToChannel comment on this.  - aquanight
    Dim i As Byte
    Dim Nick, Host, Name As String
    For i = 0 To basMain.TotalServices - 1
        Nick = basMain.Service(i).Nick
        Host = basMain.Service(i).Hostmask
        Name = basMain.Service(i).Name
        Call basFunctions.SendData(":" & Nick & " PART " & Channel)
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
    Call basFunctions.SendData("SERVER " & Name & " 2 :" & " " & Message & vbCrLf)
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
    Dim p() As Variant
    'Apparanetly we have to make a copy of this.
    ReDim p(LBound(Parameters) To UBound(Parameters))
    Dim idx As Long
    For idx = LBound(Parameters) To UBound(Parameters)
        If IsObject(Parameters(idx)) Then
            Set p(idx) = Parameters(idx)
        Else
            Let p(idx) = Parameters(idx)
        End If
    Next idx
    sAdminServ.HandleEvent Source, EventName, p
    sAgent.HandleEvent Source, EventName, p
    sChanServ.HandleEvent Source, EventName, p
    sDebugServ.HandleEvent Source, EventName, p
    sMassServ.HandleEvent Source, EventName, p
    sNickServ.HandleEvent Source, EventName, p
    sOperServ.HandleEvent Source, EventName, p
    sRootServ.HandleEvent Source, EventName, p
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
    NUHMaskIsMatch = (User.Nick & "!" & User.UserName & "@" & User.HostName Like Mask) Or (User.VirtHost <> "" And User.Nick & "!" & User.UserName & "@" & User.VirtHost Like Mask)
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

'Source for below 3 functions:
'http://www.motobit.com/tips/detpg_Base64.htm and http://www.motobit.com/tips/detpg_Base64Encode.htm
'Modified to take advantage of VB6 stuff that VBS doesn't have :P .

Public Function Base64Encode(ByVal inData As String) As String
    'rfc1521
    '2001 Antonin Foller, Motobit Software, http://Motobit.cz
    Const Base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    Dim sOut As String
    Dim i As Long
  
    'For each group of 3 bytes
    For i = 1 To Len(inData) Step 3
        Dim nGroup As Long
        Dim pOut As String
        Dim sGroup As String
    
        'Create one long from this 3 bytes.
        nGroup = &H10000 * Asc(Mid(inData, i, 1)) + &H100 * MyASC(Mid(inData, i + 1, 1)) + MyASC(Mid(inData, i + 2, 1))
    
        'Oct splits the long To 8 groups with 3 bits
        sGroup = Oct$(nGroup)
    
        'Add leading zeros
        sGroup = String$(8 - Len(sGroup), "0") & sGroup
    
        'Convert To base64
        pOut = Mid$(Base64, CLng("&o" & Mid(sGroup, 1, 2)) + 1, 1) + Mid$(Base64, CLng("&o" & Mid$(sGroup, 3, 2)) + 1, 1) + Mid$(Base64, CLng("&o" & Mid$(sGroup, 5, 2)) + 1, 1) + Mid$(Base64, CLng("&o" & Mid(sGroup, 7, 2)) + 1, 1)
    
        'Add the part To OutPut string
        sOut = sOut + pOut
    
        'Add a new line For Each 76 chars In dest (76*3/4 = 57)
        'If (I + 2) Mod 57 = 0 Then sOut = sOut + vbCrLf
    Next
    Select Case Len(inData) Mod 3
        Case 1: '8 bit final
            sOut = Left$(sOut, Len(sOut) - 2) + "=="
        Case 2: '16 bit final
            sOut = Left$(sOut, Len(sOut) - 1) + "="
    End Select
    Base64Encode = sOut
End Function

Private Function MyASC(ByVal OneChar As String) As Integer
    If OneChar = "" Then MyASC = 0 Else MyASC = Asc(OneChar)
End Function

' Decodes a base-64 encoded string (BSTR type).
' 1999 - 2004 Antonin Foller, http://www.motobit.com
' 1.01 - solves problem with Access And 'Compare Database' (InStr)
Function Base64Decode(ByVal base64String As String) As String
    'rfc1521
    '1999 Antonin Foller, Motobit Software, http://Motobit.cz
    Const Base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    Dim dataLength As Long, sOut As String, groupBegin As Long
  
    'remove white spaces, If any
    base64String = Replace$(base64String, vbCrLf, "")
    base64String = Replace$(base64String, vbTab, "")
    base64String = Replace$(base64String, " ", "")
  
    'The source must consists from groups with Len of 4 chars
    dataLength = Len(base64String)
    If dataLength Mod 4 <> 0 Then
        Err.Raise 1, "Base64Decode", "Bad Base64 string."
        Exit Function
    End If

  
    ' Now decode each group:
    For groupBegin = 1 To dataLength Step 4
        Dim numDataBytes As Long, CharCounter As Long, thisChar As String * 1, thisData As Long, nGroup As Long, pOut As String
        ' Each data group encodes up To 3 actual bytes.
        numDataBytes = 3
        nGroup = 0

        For CharCounter = 0 To 3
            ' Convert each character into 6 bits of data, And add it To
            ' an integer For temporary storage.  If a character is a '=', there
            ' is one fewer data byte.  (There can only be a maximum of 2 '=' In
            ' the whole string.)

            thisChar = Mid$(base64String, groupBegin + CharCounter, 1)

            If thisChar = "=" Then
                numDataBytes = numDataBytes - 1
                thisData = 0
            Else
                thisData = InStr(1, Base64, thisChar, vbBinaryCompare) - 1
            End If
            If thisData = -1 Then
                Err.Raise 2, "Base64Decode", "Bad character In Base64 string."
                Exit Function
            End If

            nGroup = 64 * nGroup + thisData
        Next
        
        Dim sGroup As String
    
        'Hex splits the long To 6 groups with 4 bits
        sGroup = Hex$(nGroup)
    
        'Add leading zeros
        sGroup = String$(6 - Len(sGroup), "0") & sGroup
    
        'Convert the 3 byte hex integer (6 chars) To 3 characters
        pOut = Chr$(CByte("&H" & Mid$(sGroup, 1, 2))) + Chr$(CByte("&H" & Mid$(sGroup, 3, 2))) + Chr$(CByte("&H" & Mid$(sGroup, 5, 2)))
    
        'add numDataBytes characters To out string
        sOut = sOut & Left$(pOut, numDataBytes)
    Next

    Base64Decode = sOut
End Function

'And these functions are translated from UnrealIRCd src/aln.c
Public Function IntToB64(ByVal val As Long) As String
    Dim map() As Variant
    map = Array("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", _
        "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", _
        "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", _
        "w", "x", "y", "z", "{", "}")
    Static b64buf As String * 7
    Dim i As Long
    i = 8
    'Unreal does some weird check to see if val is over 2^31-1, but we don't need it since Long can't do that.
    'Unreal's check just calls abort() if it is over, which we shouldn't do.
    Do
        i = i - 1
        Mid(b64buf, i, 1) = map(val And 63)
        'Now we need to do a 6-bit right shift. Unreal's code uses a signed long, and by C's standard,
        '>> on a signed integer performs an arithmetic shift. This will play havoc if val is < 0 but that
        'shouldn't happen anyway.
        val = val \ (2 ^ 6)
    Loop While val
    IntToB64 = Mid(b64buf, i)
End Function

Public Function B64ToInt(ByVal b64 As String) As Long
    Dim map() As Variant
    map = Array(-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, -1, -1, -1, -1, -1, -1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, _
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, -1, -1, -1, 36, 37, 38, 39, 40, 41, _
    42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, -1, 63, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, _
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1)
    Dim idx As Long
    Dim v As Long
    idx = 1
    v = map(Asc(Mid(b64, idx, 1)))
    idx = idx + 1
    If idx > Len(b64) Then
        B64ToInt = 0
        Exit Function
    End If
    For idx = idx To Len(b64)
        'Do a 6-bit left shift. Harder than a right.
        'Mask off bits that will fall off.
        v = v And &H3FFFFFF
        If CDbl(v) * (2 ^ 6) > 2147483647# Then
            v = FMod(v * (2 ^ 6), 2147483648#) + -2147483648#
        Else
            v = v * (2 ^ 6)
        End If
        v = v + map(Asc(Mid(b64, idx, 1)))
    Next idx
    B64ToInt = v
End Function

Public Function FMod(ByVal dividend As Double, ByVal divisor As Double) As Double
    'Floating modulus. When the Mod operator doesn't help.
    'Essentially, a % b == ((a / b) - iPart(a / b)) * b
    FMod = ((dividend / divisor) - Fix(dividend / divisor)) * divisor
End Function
