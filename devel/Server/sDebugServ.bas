Attribute VB_Name = "sDebugServ"
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
Public Const ModVersion = "1.0.0.0"

Public Sub DebugservHandler(Cmd As String, Sender As Integer)
    Dim Parameters() As String
    ReDim Parameters(0) As String
    Dim SenderNick As String
    Dim Temp As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Dim Cmdcopy As String
    Cmdcopy = Cmd
    Dim Spacer As Long, Elements As Long
    Do While InStr(Cmdcopy, " ") <> 0
        Spacer = InStr(Cmdcopy, " ")
        If Spacer <> 0 Then
            Parameters(Elements) = Left(Cmdcopy, Spacer - 1)
        Else
            Parameters(Elements) = Cmdcopy
        End If
        Cmdcopy = Right(Cmdcopy, Len(Cmdcopy) - Spacer)
        Elements = Elements + 1
        ReDim Preserve Parameters(Elements)
    Loop
    Parameters(Elements) = Cmdcopy
    
    Select Case UCase(Parameters(0))
        Case "MYEMAIL"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, basMain.Users(Sender).EMail)
        Case "MYACCESS"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, CStr(basMain.Users(Sender).Access))
        Case "MYSERVICESPERMISSIONS"
            Temp = basFunctions.ReturnUserServicesPermissions(Sender)
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, Temp)
        Case "MYABUSETEAMSTATUS"
            Temp = basFunctions.IsAbuseTeamMember(Sender)
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, Temp)
        Case "MYMODES"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, basMain.Users(Sender).Modes)
        Case "HELP"
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "DebugServ:")
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, " ")
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, "  If you don't know what debugserv is, then at the moment you shouldn't be using these services...")
        Case Else
            Call basFunctions.SendMessage(basMain.Service(11).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

