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

Public Sub ParseConfigurationFile(File As String)
    'Authored by w00t 27/06/2004
    'Probably dodgy as hell, but hey. File must be fully qualified, ie "./winse.conf"
    'wont work.
    
    'The directives.
    Dim Directives(10) As String
    Dim fd As Integer 'hope so :|
    Dim i As Integer
    Dim ConfigLine As String
    Dim ConfigCopy As String
    Dim DirectiveVal As String
    
    'Initialise directives.
    Directives(0) = "CONFIGVER"
    Directives(1) = "UPLINKHOST"
    Directives(2) = "UPLINKPORT"
    Directives(3) = "UPLINKNAME"
    Directives(4) = "UPLINKPASSWORD"
    Directives(5) = "UPLINKTYPE"
    Directives(6) = "SERVERNAME"
    Directives(7) = "SERVERDESCRIPTION"
    Directives(8) = "SERVERNUMERIC"
    Directives(9) = "SERVICESMASTER"
    Directives(10) = "DEFAULTMESSAGETYPE"
    
    Call basFunctions.LogEvent(basMain.LogTypeDebug, "Checking conf existance")
    fd = FreeFile
    Open File For Append As #fd
        If LOF(fd) = 0 Then
            'Error, given config file doesnt exist.
            Call basFunctions.LogEvent(basMain.LogTypeError, Replies.ConfigFileDoesntExist)
            'clean up, terminate.
            Close #fd
            Kill File
            End
        End If
    Close #fd
    'k, by here, the file is confirmed as existing, so now... try to parse it :|
    'Make sure fd is still valid.
    Call basFunctions.LogEvent(basMain.LogTypeDebug, "Conf exists, parsing.")
    fd = FreeFile
    Open File For Input As #fd
NextLine:
        Do While Not EOF(fd)
            Line Input #fd, ConfigLine
            ConfigLine = Trim(ConfigLine)
            If Left(ConfigLine, 1) = "#" Or ConfigLine = "" Then
                'if its a comment, ignore. (update: also ignore blank lines :P)
                GoTo NextLine
            End If
            'Ok, now we need to :|:| try get stuff. Make a copy of the line in
            'ConfigCopy so we can mutilate it. (make it ucase for searching)
            ConfigCopy = UCase(ConfigLine)
            'See what directive we have...
            For i = 0 To UBound(Directives)
                If Left(ConfigCopy, Len(Directives(i))) = Directives(i) Then
                    'We have a match!
                    DirectiveVal = Right(ConfigLine, Len(ConfigLine) - (Len(Directives(i)) + 1))
                    Select Case Directives(i)
                        Case "CONFIGVER"
                            If DirectiveVal <> "1.0.0.0" Then
                                Call basFunctions.LogEvent(basMain.LogTypeError, Replies.ConfigFileUnexpectedConfVersion)
                            End If
                        Case "UPLINKHOST"
                            basMain.Config.UplinkHost = DirectiveVal
                        Case "UPLINKPORT"
                            basMain.Config.UplinkPort = DirectiveVal
                        Case "UPLINKNAME"
                            basMain.Config.UplinkName = DirectiveVal
                        Case "UPLINKPASSWORD"
                            basMain.Config.UplinkPassword = DirectiveVal
                        Case "UPLINKTYPE"
                            'ignore for now.
                        Case "SERVERNAME"
                            basMain.Config.ServerName = DirectiveVal
                        Case "SERVERDESCRIPTION"
                            basMain.Config.ServerDescription = DirectiveVal
                        Case "SERVERNUMERIC"
                            basMain.Config.ServerNumeric = DirectiveVal
                        Case "SERVICESMASTER"
                            basMain.Config.ServicesMaster = DirectiveVal
                        Case "DEFAULTMESSAGETYPE"
                            'Defines the default for users().msgstyle True=notice false=privmsg
                            Select Case DirectiveVal
                                Case "P", "p"
                                    basMain.Config.DefaultMessageType = False
                                Case "N", "n"
                                    basMain.Config.DefaultMessageType = True
                                Case Else
                                    Call basFunctions.LogEvent(basMain.LogTypeWarn, Replies.ConfigFileInvalidMessageType)
                                    basMain.Config.DefaultMessageType = True
                            End Select
                    End Select
                    GoTo NextLine
                End If
            Next i
            'No match. Warn and continue.
            Call basFunctions.LogEvent(basMain.LogTypeWarn, Replace(Replies.ConfigFileUnknownDirective, "%n", ConfigLine))
        Loop
    Close #fd
End Sub
