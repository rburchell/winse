VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CommandDispatcher"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
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

'This is the command dispatcher allocated in the new
'command parser. By (ab)using late binding, we can make
'implementing more commands easier by simply adding
'Public Subs here.

'All Subs here should have the same signature, which
'is:
'Public Sub <name>(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
'Note that Source is a String, which means for users,
'it will be the nick, NOT the UserID! The reason for
'this is because servers can send messages too, and
'we don't have server -> ID mapping (nor do I really
'plan on it :P ).
'RawCmd is the raw argument stirng, in case we need it
'for some reason.

'Here is an example :P
Public Sub Ping(ByVal Source As String, ByRef Args() As String, ByVal RawCmd As String)
    If UBound(Args) = 0 Then 'LBound() = 0, so 1 arg.
        basFunctions.SendData ":" + basMain.Config.ServerName + " PONG :" + Args(0)
    ElseIf UBound(Args) = 1 Then '2 args.
        basFunctions.SendData ":" + basMain.Config.ServerName = " PONG " + Args(0) + " :" + Args(1)
    End If
End Sub
