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

Public Sub OperservHandler(Cmd As String, Sender As Integer)
    Dim SenderNick As String
    Dim Parameters As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Dim FirstSpace As String
    FirstSpace = InStr(Cmd, " ")
    Parameters = Right(Cmd, Len(Cmd) - FirstSpace)
    FirstSpace = InStr(Cmd, " ")
    If FirstSpace <> 0 Then Cmd = Left(Cmd, FirstSpace - 1)
    If Not basFunctions.IsOper(Sender) Then
        Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, Replies.MustBeOpered)
        Exit Sub
    End If
    If basFunctions.ReturnUserServicesPermissions(Sender) < 10 Then
        Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, Replies.InsufficientPermissions)
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
            Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(Sender As Integer)
    Dim SenderNick As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "OperServ Commands:")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  *AKILL      - Manipulate the AKILL list")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  *CLEAR      - Wipe channel modes/users")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  GLOBAL     - Send a message to all users")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  *JUPE       - 'Jupiter' a server")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  *LISTADM    - List all Services Operator.")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  *QLINE      - Let make services a global QLINE on a nick")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  *SPECS      - Show what you can do.")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  *TRACE      - List all user match the host you search.")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  *TRIGGER    - Control clone warnings")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  *UINFO      - View additional details about a client")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  *ABUSER     - Mark a user for abuse team review")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  ")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  ")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  Notice: For more Information type /msg OperServ HELP command")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  Notice: All commands sent to OperServ are logged!")
    Call basFunctions.SendMessage(basMain.Service(4).Nick, SenderNick, "  ")
End Sub

Private Sub Version(Sender As Integer)
    Call basFunctions.SendMessage(basMain.Service(4).Nick, basFunctions.ReturnUserName(Sender), AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(4).Nick & "[" & sOperServ.ModVersion & "]")
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

