Attribute VB_Name = "basFileIO"
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

Private Declare Function GetPrivateProfileString Lib "kernel32" Alias "GetPrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, ByVal lpDefault As String, ByVal lpReturnedString As String, ByVal nSize As Long, ByVal lpFileName As String) As Long
Private Declare Function WritePrivateProfileString Lib "kernel32" Alias "WritePrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, ByVal lpString As Any, ByVal lpFileName As String) As Long

Public Function GetInitEntry(InitFileName As String, Section As String, KeyName As String, Optional Default As String = "") As String
    Dim Buffer As String, InitFile As String
    InitFile = App.Path & "\databases\" & InitFileName
    Buffer = String(2048, " ")
    GetInitEntry = Left(Buffer, GetPrivateProfileString(Section, ByVal KeyName, Default, Buffer, Len(Buffer), InitFile))
End Function
Public Function SetInitEntry(InitFileName As String, Section As String, KeyName As String, Value As String) As Long
    Dim InitFile As String
    InitFile = App.Path & "\databases\" & InitFileName
    If Len(KeyName) > 0 And Len(Value) > 0 Then
        SetInitEntry = WritePrivateProfileString(Section, ByVal KeyName, ByVal Value, InitFile)
    ElseIf Len(KeyName) > 0 Then
        SetInitEntry = WritePrivateProfileString(Section, ByVal KeyName, vbNullString, InitFile)
    Else
        SetInitEntry = WritePrivateProfileString(Section, vbNullString, vbNullString, InitFile)
    End If
End Function
