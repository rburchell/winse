Attribute VB_Name = "sAdminServ"
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
Public Const ModVersion = "0.0.0.3"

Public Sub AdminservHandler(Cmd As String, Sender As Integer)
    Dim Parameters() As String
    Dim SenderNick As String
    
    SenderNick = basFunctions.ReturnUserName(Sender)
    Parameters() = basFunctions.ParseBuffer(Cmd)

    If Not basFunctions.IsServicesAdmin(Sender) Then
        Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, Replies.MustBeAServiceAdmin)
        Exit Sub
    End If
    If Not basFunctions.HasFlag(Sender, AccFlagCoMaster) And Not basFunctions.HasFlag(Sender, AccFlagMaster) Then
        Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, Replies.MustBeAServicesMasterOrComaster)
        Exit Sub
    End If
    Select Case UCase(Parameters(0))
        'imho, those with access 10 shouldnt be able to jupe... --w00t
        Case "JUPE"
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, Replies.InsufficientParameters)
            Else
                'remember to add "sender" to jupe paramlist
                Call sAdminServ.Jupe(Sender, Parameters)
            End If
        Case "HELP"
            Call sAdminServ.Help(Sender)
        Case "VERSION"
            Call sAdminServ.Version(Sender)
        Case "ACCESS"
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Call sAdminServ.Access(Sender, Parameters(1), Parameters(2))
        Case "FLAGS"
            Call sAdminServ.Flags(Sender, Parameters(1), Parameters(2))
        Case "GVERSION"
            Call sAdminServ.GlobalVersion(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(Sender As Integer)
    Dim SenderNick As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "AdminServ Commands:")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "  ACCESS <nick> <level(1-255)> - Sets/modifies user access.")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "  *SETODESC  - Add note in whois for Services Operator")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "  FLAGS     - Modify services access flags")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "  *SET        - Set various global Services options")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "  *SETTINGS   - View Services settings")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "  *STATS      - Show status of Services and network")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "  GVERSION    - Show version status of all services.")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "  Notice: For more Information type /msg AdminServ HELP command")
End Sub

Private Sub GlobalVersion(Sender As Integer)
    'Prints the version of all (official) services.
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, " Global Version Information:")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  AdminServ - v" & sAdminServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  Agent     - v" & sAgent.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  BotServ   - v" & sBotServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  ChanServ  - v" & sChanServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  DebugServ - v" & sDebugServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  HostServ  - v" & sHostServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  MassServ  - v" & sMassServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  MemoServ  - v" & sMemoServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  NickServ  - v" & sNickServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  OperServ  - v" & sOperServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  RootServ  - v" & sRootServ.ModVersion)
End Sub

Private Sub Version(Sender As Integer)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basFunctions.ReturnUserName(Sender), AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(5).Nick & "[" & sAdminServ.ModVersion & "]")
End Sub

Private Function Flags(Sender As Integer, Action As String, TargetNick As String)
    Dim UserID As Integer
    Select Case UCase(Action)
        Case "ABUSETEAMADD"
            UserID = basFunctions.ReturnUserIndex(TargetNick)
            If UserID = -1 Then
                Call basFunctions.SendMessage(basMain.Service(5).Nick, basFunctions.ReturnUserName(Sender), Replies.UserDoesntExist)
                Exit Function
            End If
            basMain.Users(UserID).AbuseTeam = True
            If basFunctions.IsNickRegistered(basMain.Users(UserID).Nick) Then
                Call basFileIO.SetInitEntry("users.db", basMain.Users(Sender).Nick, "AbuseTeam", "True")
            End If
            Call basFunctions.SendMessage(basMain.Service(5).Nick, basFunctions.ReturnUserName(Sender), Replace(Replies.AdminServUserAddToAbuseTeam, "%n", TargetNick))
        Case "ABUSETEAMDEL"
            UserID = basFunctions.ReturnUserIndex(TargetNick)
            If UserID = -1 Then
                Call basFunctions.SendMessage(basMain.Service(5).Nick, basFunctions.ReturnUserName(Sender), Replies.UserDoesntExist)
                Exit Function
            End If
            basMain.Users(UserID).AbuseTeam = False
            If basFunctions.IsNickRegistered(basMain.Users(UserID).Nick) Then
                Call basFileIO.SetInitEntry("users.db", basMain.Users(Sender).Nick, "AbuseTeam", "True")
            End If
            Call basFunctions.SendMessage(basMain.Service(5).Nick, basFunctions.ReturnUserName(Sender), Replace(Replies.AdminServUserAddToAbuseTeam, "%n", TargetNick))
    End Select
End Function

Private Function Access(Sender As Integer, TargetNick As String, NewAccess As String)
    Dim TargetIndex As Integer
    Dim Successful As Boolean
    'Dont need to check if sender is comaster since AdminServ checks will
    'do that for us (we hope)
    If (InStr(1, NewAccess, AccFlagCoMaster) > 0 Or InStr(1, NewAccess, AccFlagMaster) > 0) And Not basFunctions.HasFlag(Sender, AccFlagMaster) Then
        'That bastard is trying to add another comaster! He cant do that!
        Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, Replies.AdminServCantAddCoMaster)
        Exit Function
    End If
    TargetIndex = basFunctions.ReturnUserIndex(TargetNick)
    If HasFlag(TargetIndex, AccFlagCoMaster) And Not basFunctions.HasFlag(Sender, AccFlagMaster) Then
        'That bastard is trying to change a comaster's access! He cant do that!
        Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, Replies.AdminServCantModCoMaster)
        Exit Function
    End If
    Successful = True
    If TargetIndex <> -1 Then
        basFunctions.SetFlags TargetIndex, NewAccess
    Else
        Successful = False
    End If
    If basFunctions.IsNickRegistered(TargetNick) Then
        Call basFileIO.SetInitEntry("users.db", TargetNick, "Access", CStr(Users(TargetIndex).Access))
    Else
        Successful = False
    End If
    If Successful = True Then
        Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, Replace(Replies.AdminServAccessModified, "%n", TargetNick))
    Else
        Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, Replies.UserDoesntExist)
    End If
End Function

Public Sub Jupe(Sender As Integer, Parameters() As String)
    Dim Message As String
    Dim i As Integer
    'ASSUMPTIONS:
    'P[0] - JUPE
    'P[1] - Instruction.
    'P[2] - Servername
    'P[3>] (if given) - Message/description.
    If InStr(Parameters(2), ".") = 0 Then
        'Unreal doesnt like servernames without periods in them for some reason.
        'If this check isnt here, it crashes. So we'd best send a scream out about
        'someone trying to crash services??
        Call basFunctions.LogEventWithMessage(basMain.LogTypeError, Replace(Replies.AdminServJupeFishyNameCheck, "%n", basMain.Users(Sender).Nick))
        Exit Sub
    End If
    For i = 3 To UBound(Parameters)
        Message = Message & " " & Parameters(i)
    Next i
    Select Case UCase(Parameters(1))
        Case "ADD"
            'first, ensure server isnt connected (else things could get messy!)
            Call basFunctions.DelServer(Parameters(2), Message)
            'now send SERVER.
            Call basFunctions.AddServer(Parameters(2), Message)
        Case "DEL"
            'just send a delserver, we need no message.
            Call basFunctions.DelServer(Parameters(2))
    End Select
End Sub

'Callin subs for channel mode changes
Public Sub HandlePrefix(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As Integer)

End Sub

Public Sub HandleModeTypeA(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeB(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeC(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)

End Sub

Public Sub HandleModeTypeD(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleCommand(ByVal Sender As String, ByVal Cmd As String, ByRef Args() As String)

End Sub

Public Sub HandleUserMode(ByVal UserID As Integer, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleTick(ByVal Interval As Single)

End Sub

