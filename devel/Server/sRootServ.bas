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

Public Sub RootservHandler(Cmd As String, Sender As Integer)
    Dim SenderNick As String
    Dim Parameters As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Dim FirstSpace As String
    FirstSpace = InStr(Cmd, " ")
    Parameters = Right(Cmd, Len(Cmd) - FirstSpace)
    FirstSpace = InStr(Cmd, " ")
    If FirstSpace <> 0 Then Cmd = Left(Cmd, FirstSpace - 1)
    If Not basFunctions.IsServicesAdmin(Sender) Then
        Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, Replies.MustBeAServiceAdmin)
        Exit Sub
    End If
    If basFunctions.ReturnUserServicesPermissions(Sender) < 100 Then
        Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, Replies.MustBeAServicesMasterOrComaster)
        Exit Sub
    End If
    Select Case UCase(Cmd)
        Case "HELP"
            Call sRootServ.Help(Sender)
        Case "SHUTDOWN"
            Call sRootServ.Shutdown(Sender, Parameters)
        Case "VERSION"
            Call sRootServ.Version(Sender)
        Case "RAW"
            Call sRootServ.Raw(Sender, Parameters)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(Sender As Integer)
    Dim SenderNick As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, "RootServ Commands:")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, "  *CHANSNOOP  - Channel Snoop Feature")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, "  *REFERENCE  - Snoop symbol Reference")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, "  *FLOODRESET - Reset someone's floodlevel manually.")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, "  *INJECT     - Send RAW command to Services.")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, "  *RESTART    - SQUIT and reconnect services.")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, "  SHUTDOWN    - SQUIT and shutdown services.")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, "  RAW         - Send RAW command to Server " & Chr(3) & "4BE CAREFUL!!.")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, "  Notice: For more Information type /msg RootServ HELP command")
    Call basFunctions.SendMessage(basMain.Service(6).Nick, SenderNick, "  Notice: All commands sent to RootServ are logged!")
End Sub

Private Sub Version(Sender As Integer)
    Call basFunctions.SendMessage(basMain.Service(6).Nick, basFunctions.ReturnUserName(Sender), AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(6).Nick & "[" & sRootServ.ModVersion & "]")
End Sub

Private Sub Shutdown(Sender As Integer, Message As String)
    Call basFunctions.GlobalMessage("Services shutting down on request of " & Sender & " [" & Message & "]")
    Call basFunctions.SquitServices
    End
End Sub

Private Sub Raw(Sender As Integer, RawString As String)
    Call basFunctions.SendData(RawString)
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
