Attribute VB_Name = "sRootServ"
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
Public Const ModVersion = "0.0.0.1"

Public Sub RootservHandler(ByVal Cmd As String, ByVal Sender As User)
    Dim SenderNick As String
    Dim Parameters As String
    SenderNick = Sender.Nick
    Dim FirstSpace As String
    FirstSpace = InStr(Cmd, " ")
    Parameters = Right(Cmd, Len(Cmd) - FirstSpace)
    FirstSpace = InStr(Cmd, " ")
    If FirstSpace <> 0 Then Cmd = Left(Cmd, FirstSpace - 1)
    If Not Sender.HasFlag(AccFlagCanRootServ) Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, Replies.RootServNeedPermissions)
        Exit Sub
    End If
    Select Case UCase(Cmd)
        Case "HELP"
            Call sRootServ.Help(Sender)
        Case "INJECT"
            Call sRootServ.Inject(Sender, Parameters)
        Case "SHUTDOWN"
            Call sRootServ.Shutdown(Sender, Parameters)
        Case "RAW"
            Call sRootServ.Raw(Sender, Parameters)
        Case "VERSION"
            Call sRootServ.Version(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(ByVal Sender As User)
    Dim SenderNick As String
    SenderNick = Sender.Nick
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, "RootServ Commands:")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, "  *CHANSNOOP  - Channel Snoop Feature")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, "  *REFERENCE  - Snoop symbol Reference")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, "  *FLOODRESET - Reset someone's floodlevel manually.")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, "  INJECT     - Preform a services command as another user")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, "  *RESTART    - SQUIT and reconnect services.")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, "  SHUTDOWN    - SQUIT and shutdown services.")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, "  RAW         - Send RAW command to Server " & Chr(3) & "4BE CAREFUL!!.")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, "  Notice: For more Information type /msg RootServ HELP command")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, SenderNick, "  Notice: All commands sent to RootServ are logged!")
End Sub

Private Sub Version(ByVal Sender As User)
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, Sender.Nick, AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(SVSINDEX_ROOTSERV).Nick & "[" & sRootServ.ModVersion & "]")
End Sub

Private Sub Shutdown(ByVal Sender As User, Message As String)
    Call basFunctions.GlobalMessage("Services shutting down on request of " & Sender.Nick & " [" & Message & "]")
    Call basFunctions.SquitServices("SHUTDOWN Command by " + Users(Sender).Nick)
    End
End Sub

Private Sub Raw(ByVal Sender As User, RawString As String)
    Call basFunctions.SendData(RawString)
End Sub

Private Sub Inject(ByVal Sender As User, sParameters As String)
    If Not Sender.HasFlag(AccFlagCanRootServInject) Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, Users(Sender).Nick, Replies.RootServInjectNeedPermissions)
        Exit Sub
    End If
    Dim InjectData() As String, TargetID As User
    InjectData = Split(sParameters, " ", 3)
    TargetID = basMain.Users(InjectData(0))
    Select Case UCase(InjectData(1))
        Case "NICKSERV"
            Call sNickServ.NickservHandler(InjectData(3), TargetID)
        Case "CHANSERV"
            Call sChanServ.ChanservHandler(InjectData(3), TargetID)
        Case "MEMOSERV"
            Call sMemoServ.MemoservHandler(InjectData(3), TargetID)
        Case "BOTSERV"
            Call sBotServ.BotservHandler(InjectData(3), TargetID)
    End Select
    If basMain.Config.InjectToOperServices Then
        If Sender.HasFlag(AccFlagCanRootServSuperInject) Then
            Select Case UCase(InjectData(1))
                Case "OPERSERV"
                    Call sOperServ.OperservHandler(InjectData(3), TargetID)
                Case "ROOTSERV"
                    Call sRootServ.RootservHandler(InjectData(3), TargetID)
                Case "MASSSERV"
                    Call sMassServ.MassservHandler(InjectData(3), TargetID)
                Case "HOSTSERV"
                    Call sHostServ.HostservHandler(InjectData(3), TargetID)
            End Select
        Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, Users(Sender).Nick, Replies.RootServSuperInjectNeedPermissions)
        End If
    Else
        Select Case UCase(InjectData(1))
            Case "OPERSERV", "ROOTSERV", "MASSSERV", "HOSTSERV"
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, Users(Sender).Nick, Replies.RootServSuperInjectDisabled)
            Case "ADMINSERV", "AGENT"
                Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, Users(Sender).Nick, Replies.RootServSuperInjectDisabled)
        End Select
    End If
    Select Case UCase(InjectData(1))
        Case "ADMINSERV", "AGENT"
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_ROOTSERV).Nick, Users(Sender).Nick, Replies.RootServAbusiveInjectDisabled)
    End Select
' None to AGENT or ADMINSERV for obvious reasons... (Not abuse team? Give yourself more access?)
End Sub

Public Sub HandlePrefix(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As User)

End Sub

Public Sub HandleModeTypeA(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeB(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeC(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)

End Sub

Public Sub HandleModeTypeD(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleCommand(ByVal Sender As String, ByVal Cmd As String, ByRef Args() As String)

End Sub

Public Sub HandleUserMode(ByVal User As User, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleTick(ByVal Interval As Single)

End Sub

