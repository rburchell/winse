Attribute VB_Name = "sBotServ"
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
Public Const ModVersion = "0.0.0.0"

Public Sub BotservHandler(ByVal Cmd As String, ByVal Sender As User)

End Sub

Public Sub HandleEvent(ByVal Source As String, ByVal EventName As String, Parameters() As Variant)
    If EventName = basEvents.ChanMsg Then
        'Channel Message!
        Dim chptr As Channel, sptr As User, msg As String
    End If
End Sub
