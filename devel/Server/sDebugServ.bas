Attribute VB_Name = "sDebugServ"
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
Public Const ModVersion = "1.0.0.0"

Public Sub DebugservHandler(Cmd As String, Sender As Integer)
    Dim Parameters() As String
    Dim SenderNick As String
    Dim i As Variant 'i am soooo naughty >:)
    
    SenderNick = basFunctions.ReturnUserName(Sender)
    Parameters() = basFunctions.ParseBuffer(Cmd)
    
    Select Case UCase(Parameters(0))
        Case "MYEMAIL"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, basMain.Users(Sender).EMail)
        Case "MYACCESS"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, CStr(basMain.Users(Sender).Access))
        Case "MYABUSETEAMSTATUS"
            i = basFunctions.IsAbuseTeamMember(Sender)
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, CStr(i))
        Case "MYMODES"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, basMain.Users(Sender).Modes)
        Case "HELP"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "DebugServ:")
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "If you don't know what debugserv is, then at the moment you shouldn't be using these services...")
        Case Else
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

