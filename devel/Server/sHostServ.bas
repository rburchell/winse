Attribute VB_Name = "sHostServ"
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

Public Sub HostservHandler(ByVal Cmd As String, ByVal Sender As User)
    Dim Parameters() As String
    Dim SenderNick As String
    
    SenderNick = Sender.Nick
    Parameters() = basFunctions.ParseBuffer(Cmd)
    
    Select Case UCase(Parameters(0))
        Case "CHGHOST"
            If UBound(Parameters) = 2 Then
                If Users.Exists(Parameters(1)) Then Users(Parameters(1)).VirtHost = Parameters(2)
            End If
        Case "SET"
            If UBound(Parameters) = 2 Then
                Call sHostServ.DoSet(SenderNick, Parameters(1), Parameters(2))
            End If
        Case "UNSET"
            If UBound(Parameters) = 1 Then
                Call sHostServ.DoUnSet(SenderNick, Parameters(1))
            End If
        Case "LIST"
            If UBound(Parameters) = 0 Then
                Call sHostServ.DoList(SenderNick)
            End If
        Case "HELP"
            If UBound(Parameters) > 0 Then
                Call sHostServ.Help(Sender, Split(Cmd, " ", 2)(1))
            Else
                Call sHostServ.Help(Sender, "")
            End If
        Case "VERSION"
            Call sHostServ.Version(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_HOSTSERV).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(ByVal Sender As User, ByVal Cmd As String)
    Dim SenderNick As String, s() As String
    SenderNick = Sender.Nick
    s = Split(Cmd, " ")
    basFunctions.CommandHelp Sender, s, "chanserv", SVSINDEX_HOSTSERV
End Sub

Private Sub DoList(Sender As String)
    Dim l As Integer, UsrExist As Boolean, i As Integer
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_HOSTSERV).Nick, Sender, "All vHosts (Bold if in use)")
    For l = LBound(sNickServ.DB) To UBound(sNickServ.DB)
        If Not sNickServ.DB(l).VHost = "" Then
            UsrExist = False
            For i = 0 To Users.Count
                If Users(i).VirtHost = sNickServ.DB(l).VHost Then
                    UsrExist = True
                    Exit For
                End If
            Next i
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_HOSTSERV).Nick, Sender, IIf(UsrExist, MIRC_BOLD, "") & sNickServ.DB(l).VHost & IIf(UsrExist, MIRC_BOLD, ""))
        End If
    Next l
End Sub

Private Sub Version(Sender As User)
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, Sender.Nick, AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(SVSINDEX_NICKSERV).Nick & "[" & sNickServ.ModVersion & "]")
End Sub

Private Sub DoSet(Setter As String, Nick As String, Host As String)
    Dim ReturnVal As Byte
    Const Returns_DBNoUser As Byte = 1
    Const Returns_IRCNoUser As Byte = 2
    ReturnVal = 0
    If Users.Exists(Nick) Then
        Call basFunctions.SendData("CHGHOST " & Nick & " " & Host)
        Call basFunctions.SendMessage(Service(SVSINDEX_HOSTSERV).Nick, Nick, "Your hidden host is now " + MIRC_BOLD + Host + MIRC_BOLD)
        Users(Nick).VirtHost = Host
    Else
        ReturnVal = ReturnVal Or Returns_IRCNoUser
    End If
    If Not SetDBHost(Users(Nick), Host) Then ReturnVal = ReturnVal Or Returns_DBNoUser
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_HOSTSERV).Nick, Setter, IIf(ReturnVal And Returns_DBNoUser, IIf(ReturnVal And Returns_IRCNoUser, "No such user in database or online", "User not registered.  Session vHost Set."), "vHost Set"))
End Sub

Private Sub DoUnSet(Setter As String, Nick As String)
    If Users.Exists(Nick) Then
        Call basFunctions.SendData("SVSMODE " + Nick + " -xt")
        Call basFunctions.SendMessage(Service(SVSINDEX_HOSTSERV).Nick, Nick, "Your hidden host has been unset. To resume standard host cloaking, type " + MIRC_BOLD + "/mode " + Nick + " +x" + MIRC_BOLD)
    End If
    Call SetDBHost(Users(Nick), "")
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_HOSTSERV).Nick, Setter, "vHost unset")
End Sub

' Event And Remote Functions

Public Sub NickServ_Identify(Identified As User)
    Call basFunctions.SendData("CHGHOST " & Identified.Nick & " " & GetDBHost(Identified))
    Users(Identified.Nick).VirtHost = GetDBHost(Identified)
End Sub

Private Function GetDBHost(Who As User) As String
    If sNickServ.DBIndexOf(Who.IdentifiedToNick) >= 0 Then GetDBHost = sNickServ.DB(sNickServ.DBIndexOf(Who.IdentifiedToNick)).VHost
End Function

Private Function SetDBHost(Who As User, NewHost As String) As Boolean
    SetDBHost = False
    If sNickServ.DBIndexOf(Who.IdentifiedToNick) >= 0 Then
        sNickServ.DB(sNickServ.DBIndexOf(Who.IdentifiedToNick)).VHost = NewHost
        SetDBHost = True
    End If
End Function
