Attribute VB_Name = "sAdminServ"
' Winse - WINdows SErvices. IRC services for Windows.
' Copyright (C) 2004 w00t[w00t@netronet.org]
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
'
' Contact Maintainer: w00t[w00t@netronet.org]
Option Explicit

Public Const ModVersion = "0.0.0.1"

Public Sub AdminservHandler(Cmd As String, Sender As Integer)
    Dim SenderNick As String
    Dim Cmdcopy As String
    Dim Parameters() As String
    ReDim Parameters(0) As String
    Dim Spacer As Integer
    Dim Elements As Integer
    
    SenderNick = basFunctions.ReturnUserName(Sender)
    
    Cmdcopy = Cmd
    Do While InStr(Cmdcopy, " ") <> 0
        Spacer = InStr(Cmdcopy, " ")
        If Spacer <> 0 Then
            Parameters(Elements) = Left(Cmdcopy, Spacer - 1)
        Else
            Parameters(Elements) = Cmdcopy
        End If
        Cmdcopy = Right(Cmdcopy, Len(Cmdcopy) - Spacer)
        Elements = Elements + 1
        ReDim Preserve Parameters(Elements) As String
    Loop
    Parameters(Elements) = Cmdcopy

    If Not basFunctions.IsServicesAdmin(Sender) Then
        Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, Replies.MustBeAServiceAdmin)
        Exit Sub
    End If
    If basFunctions.ReturnUserServicesPermissions(Sender) < 99 Then
        Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, Replies.MustBeAServicesMasterOrComaster)
        Exit Sub
    End If
    Select Case UCase(Parameters(0))
        Case "HELP"
            Call sAdminServ.Help(Sender)
        Case "VERSION"
            Call sAdminServ.Version(Sender)
        Case "ACCESS"
            If Elements < 2 Then
                Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            If CDec(Parameters(2)) > 255 Then
                Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, Replies.AccessTooHigh)
            End If
            Call sAdminServ.Access(Sender, Parameters(1), CByte(Parameters(2)))
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
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "  VERSION    - Show version status of all services.")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, SenderNick, "  Notice: For more Information type /msg AdminServ HELP command")
End Sub

Private Sub GlobalVersion(Sender As Integer)
    'Prints the version of all (official) services.
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, " Global Version Information:")
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  AdminServ - v" & sAdminServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  Agent     - v" & sAgent.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  BotServ   - v") '& sBotServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  ChanServ  - v" & sChanServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  DebugServ - v" & sDebugServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  HostServ  - v") '& sHostServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  MassServ  - v" & sMassServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  MemoServ  - v") '& sMemoServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  NickServ  - v" & sNickServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  OperServ  - v" & sOperServ.ModVersion)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, "  RootServ  - v" & sRootServ.ModVersion)
End Sub

Private Sub Version(Sender As Integer)
    Call basFunctions.SendMessage(basMain.Service(5).Nick, basFunctions.ReturnUserName(Sender), AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(5).Nick & "[" & sAdminServ.ModVersion & "]")
End Sub

Private Function Flags(Sender As Integer, Action As String, TargetNick As String)
    Dim UserId As Integer
    Select Case UCase(Action)
        Case "ABUSETEAMADD"
            UserId = basFunctions.ReturnUserIndex(TargetNick)
            If UserId = -1 Then
                Call basFunctions.SendMessage(basMain.Service(5).Nick, basFunctions.ReturnUserName(Sender), Replies.UserDoesntExist)
                Exit Function
            End If
            basMain.Users(UserId).AbuseTeam = True
            If basFunctions.IsNickRegistered(basMain.Users(UserId).Nick) Then
                Call basFileIO.SetInitEntry("users.db", basMain.Users(Sender).Nick, "AbuseTeam", "True")
            End If
            Call basFunctions.SendMessage(basMain.Service(5).Nick, basFunctions.ReturnUserName(Sender), Replies.AdminServUserAddToAbuseTeam)
        Case "ABUSETEAMDEL"
            UserId = basFunctions.ReturnUserIndex(TargetNick)
            If UserId = -1 Then
                Call basFunctions.SendMessage(basMain.Service(5).Nick, basFunctions.ReturnUserName(Sender), Replies.UserDoesntExist)
                Exit Function
            End If
            basMain.Users(UserId).AbuseTeam = False
            If basFunctions.IsNickRegistered(basMain.Users(UserId).Nick) Then
                Call basFileIO.SetInitEntry("users.db", basMain.Users(Sender).Nick, "AbuseTeam", "True")
            End If
            Call basFunctions.SendMessage(basMain.Service(5).Nick, basFunctions.ReturnUserName(Sender), Replies.AdminServUserDelFromAbuseTeam)
    End Select
End Function

Private Function Access(Sender As Integer, TargetNick As String, NewAccess As Byte)
    Dim TargetIndex As Integer
    Dim IndexVal As Integer
    Dim Successful As Boolean
    'Dont need to check if sender's access >=99 since AdminServ checks will
    'do that for us (we hope)
    If NewAccess >= basMain.Users(Sender).Access And basMain.Users(Sender).Access < 100 Then
        'That bastard is trying to add permissions above his own!!!
        'They must be a comaster (access==99) so tell him to get b0rked!
        Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, Replies.AdminServCantAddMaster)
        Exit Function
    End If
    IndexVal = basFunctions.ReturnUserIndex(TargetNick)
    If IndexVal <> -1 Then
        basMain.Users(TargetIndex).Access = NewAccess
        Successful = True
    End If
    If basFunctions.IsNickRegistered(basMain.Users(Sender).Nick) Then
        Call basFileIO.SetInitEntry("users.db", TargetNick, "Access", CStr(NewAccess))
        Successful = True
    End If
    If Successful = True Then
        Call basFunctions.SendMessage(basMain.Service(5).Nick, basMain.Users(Sender).Nick, Replies.AdminServAccessModified)
    End If
End Function
