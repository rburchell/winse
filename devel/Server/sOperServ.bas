Attribute VB_Name = "sOperServ"
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

Public Sub OperservHandler(ByVal Cmd As String, ByVal Sender As User)
    Dim SenderNick As String
    Dim Parameters As String
    SenderNick = Sender.Nick
    Dim FirstSpace As String
    FirstSpace = InStr(Cmd, " ")
    Parameters = Right(Cmd, Len(Cmd) - FirstSpace)
    FirstSpace = InStr(Cmd, " ")
    If FirstSpace <> 0 Then Cmd = Left(Cmd, FirstSpace - 1)
    If Not Sender.IsOper Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, Replies.MustBeOpered)
        Exit Sub
    End If
    If Not Sender.HasFlag(AccFlagCanOperServ) Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, Replies.InsufficientPermissions)
        Exit Sub
    End If
    Select Case UCase(Cmd)
        Case "HELP"
            Call sOperServ.Help(Sender)
        Case "VERSION"
            Call sOperServ.Version(Sender)
        Case "GLOBAL"
            Call basFunctions.GlobalMessage(Parameters)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(ByVal Sender As User)
    Dim SenderNick As String
    SenderNick = Sender.Nick
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "OperServ Commands:")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  *AKILL      - Manipulate the AKILL list")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  *CLEAR      - Wipe channel modes/users")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  GLOBAL     - Send a message to all users")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  *JUPE       - 'Jupiter' a server")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  *LISTADM    - List all Services Operator.")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  *QLINE      - Let make services a global QLINE on a nick")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  *SPECS      - Show what you can do.")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  *TRACE      - List all user match the host you search.")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  *TRIGGER    - Control clone warnings")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  *UINFO      - View additional details about a client")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  *ABUSER     - Mark a user for abuse team review")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  ")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  ")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  Notice: For more Information type /msg OperServ HELP command")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  Notice: All commands sent to OperServ are logged!")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, SenderNick, "  ")
End Sub

Private Sub Version(ByVal Sender As User)
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_OPERSERV).Nick, Sender.Nick, AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(SVSINDEX_OPERSERV).Nick & "[" & sOperServ.ModVersion & "]")
End Sub

'Callin subs for channel mode changes
Public Sub HandlePrefix(ByVal Source As String, ByVal Chan As channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As User)

End Sub

Public Sub HandleModeTypeA(ByVal Source As String, ByVal Chan As channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeB(ByVal Source As String, ByVal Chan As channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeC(ByVal Source As String, ByVal Chan As channel, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)

End Sub

Public Sub HandleModeTypeD(ByVal Source As String, ByVal Chan As channel, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleCommand(ByVal Sender As String, ByVal Cmd As String, ByRef Args() As String)

End Sub

Public Sub HandleUserMode(ByVal User As User, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleTick(ByVal Interval As Single)

End Sub

Public Sub HandleEvent(ByVal Source As String, ByVal EventName As String, Parameters() As Variant)

End Sub
