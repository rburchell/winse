Attribute VB_Name = "basFileIO"
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

Private Declare Function GetPrivateProfileString Lib "kernel32" Alias "GetPrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, ByVal lpDefault As String, ByVal lpReturnedString As String, ByVal nSize As Long, ByVal lpFileName As String) As Long
Private Declare Function GetPrivateProfileSection Lib "kernel32" Alias "GetPrivateProfileSectionA" (ByVal lpApplicationName As String, ByVal lpReturnedString As String, ByVal nSize As Long, ByVal lpFileName As String) As Long
Private Declare Function WritePrivateProfileString Lib "kernel32" Alias "WritePrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, ByVal lpString As Any, ByVal lpFileName As String) As Long
Private Declare Function GetPrivateProfileSectionNames Lib "kernel32" Alias "GetPrivateProfileSectionNamesA" (ByVal lpszReturnBuffer, ByVal nSize As Long, ByVal lpFileName As String) As Long

Public Function GetInitEntry(ByVal InitFileName As String, ByVal Section As String, ByVal KeyName As String, Optional ByVal Default As String = "") As String
    Dim Buffer As String, InitFile As String
    InitFile = InitFileName
    Buffer = String(2048, " ")
    GetInitEntry = Left(Buffer, GetPrivateProfileString(Section, ByVal KeyName, Default, Buffer, Len(Buffer), InitFile))
End Function

Public Function SetInitEntry(ByVal InitFileName As String, ByVal Section As String, ByVal KeyName As String, ByVal Value As String) As Long
    Dim InitFile As String
    InitFile = InitFileName
    If Len(KeyName) > 0 And Len(Value) > 0 Then
        SetInitEntry = WritePrivateProfileString(Section, ByVal KeyName, ByVal Value, InitFile)
    ElseIf Len(KeyName) > 0 Then
        SetInitEntry = WritePrivateProfileString(Section, ByVal KeyName, vbNullString, InitFile)
    Else
        SetInitEntry = WritePrivateProfileString(Section, vbNullString, vbNullString, InitFile)
    End If
End Function

'If KeyName is an empty string, the entire section
'can be deleted!
'If Section is an empty string, the entire INI FILE
'IS DELETED! :P
Public Function DeleteInitEntry(ByVal InitFileName As String, ByVal Section As String, ByVal KeyName As String)
    Dim InitFile As String
    InitFile = InitFileName
    If Section = "" Then
        'Drop the database altogether.
        Kill InitFile
        DeleteInitEntry = 0
    Else
        DeleteInitEntry = SetInitEntry(InitFileName, Section, KeyName, "")
    End If
End Function

'Returns a String Array of sections in the INI file.
Public Function ScanINISections(ByVal INIFile As String) As Variant
    Dim lRet As Long, sBuf As String
    Dim nSize As Long
    Dim InitFile As String
    InitFile = App.Path & "\databases\" & INIFile
    'Okay, we need to make this string big enough to
    'hold all of the sections... but we don't know how
    'many there will be, so here goes nothing:
    nSize = 1024
    Do
        sBuf = String(nSize + 1, Chr(0))
        lRet = GetPrivateProfileSectionNames(sBuf, nSize, InitFile)
        If lRet = 0 Then
            'GAK!!!
            Err.Raise Err.LastDllError, , "API Error!"
        ElseIf lRet = nSize - 2 Then
            'Wasn't big enough!!!
            nSize = nSize + 1024
            'Go back and do it again!
        Else
            'Fits, but may be to big, so make it fit.
            'For perfect fits, lRet is the amount of
            'data + 1.
            sBuf = Left(sBuf, lRet + 1)
            'Now get out of this loop!
            Exit Do
        End If
        'If we are going around again, make it at least
        'look like we aren't hung :) .
        DoEvents
    Loop
    'Otherwise... we're done!
    Dim v As Variant
    v = Split(sBuf, Chr(0))
    ReDim Preserve v(UBound(v) - 1)
    ScanINISections = v
End Function

'Returns an array of strings contain keys in this
'section.
Public Function ScanINISectionKeys(ByVal INIFile As String, ByVal Section As String)
    Dim lRet As Long, sBuf As String
    Dim nSize As Long
    Dim InitFile As String
    InitFile = App.Path & "\databases\" & INIFile
    'Okay, we need to make this string big enough to
    'hold all of the sections... but we don't know how
    'many there will be, so here goes nothing:
    nSize = 1024
    Do
        sBuf = String(nSize + 1, Chr(0))
        lRet = GetPrivateProfileSection(Section, sBuf, nSize, InitFile)
        If lRet = 0 Then
            'GAK!!!
            Err.Raise Err.LastDllError, , "API Error!"
        ElseIf lRet = nSize - 2 Then
            'Wasn't big enough!!!
            nSize = nSize + 1024
            'Go back and do it again!
        Else
            'Fits, but may be to big, so make it fit.
            'For perfect fits, lRet is the amount of
            'data + 1.
            sBuf = Left(sBuf, lRet + 1)
            'Now get out of this loop!
            Exit Do
        End If
        'If we are going around again, make it at least
        'look like we aren't hung :) .
        DoEvents
    Loop
    Dim v As Variant
    v = Split(sBuf, Chr(0))
    ReDim Preserve v(UBound(v) - 1)
    Dim idx As Long
    For idx = LBound(v) To UBound(v)
        If InStr(v(idx), "=") > 0 Then
            v(idx) = Left(v(idx), InStr(v(idx), "=") - 1)
        End If
    Next idx
    ScanINISectionKeys = v
End Function

'ParseConfigurationFile: moved to basMain
