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
              Call sHostServ.Help(Sender, Parameters(1))
            Else
              Call sHostServ.Help(Sender, "")
            End If
        Case "VERSION"
            Call sHostServ.Version(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_HOSTSERV).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(Sender As User, Cmd)
    Dim SenderNick As String
    SenderNick = Sender.Nick
    Select Case UCase(Cmd)
        Case "SET"
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, "NickServ Set:")
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, " COMMUNICATION [PRIVMSG/NOTICE] - Tells services how to message you.")
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, "NickServ Commands:")
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, " REGISTER")
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, " IDENTIFY")
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_NICKSERV).Nick, SenderNick, " SET")
    End Select
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
'Dim ReturnVal As Byte, Victim As String
'Const Returns_DBNoUser As Byte = 1
'Const Returns_IRCNoUser As Byte = 2
'ReturnVal = Returns_DBNoUser Or Returns_IRCNoUser
'Victim = ""
'If Users.Exists(Nick) And Len(Users(Nick).IdentifiedToNick) > 0 Then
'' ^ Use AndAlso when ported
'  Victim = Users(Nick).IdentifiedToNick
'
'  Call basFunctions.SendData("CHGHOST " & Nick & " " & Host)
'  Users(Nick).VirtHost = Host
'  ReturnVal = ReturnVal Xor Returns_IRCNoUser
'End If
'If SetDBHost(IIf(Victim = Nick Or Victim = "", Nick, Victim), Host) Then ReturnVal = ReturnVal Xor Returns_DBNoUser
'Call basFunctions.SendMessage(basMain.Service(SVSINDEX_HOSTSERV), Setter, IIf(ReturnVal And returns_nodbuser, IIf(ReturnVal And Returns_IRCNoUser, "No such user in database or online", "User not registered.  Session VHost Set."), "VHost Set"))



Dim ReturnVal As Byte
Const Returns_DBNoUser As Byte = 1
Const Returns_IRCNoUser As Byte = 2
ReturnVal = Returns_DBNoUser Or Returns_IRCNoUser
If Users.Exists(Nick) Then
  Call basFunctions.SendData("CHGHOST " & Nick & " " & Host)
  Users(Nick).VirtHost = Host
  ReturnVal = ReturnVal Xor Returns_IRCNoUser
End If
If SetDBHost(Users(Nick), Host) Then ReturnVal = ReturnVal Xor Returns_DBNoUser
Call basFunctions.SendMessage(basMain.Service(SVSINDEX_HOSTSERV).Nick, Setter, IIf(ReturnVal And Returns_DBNoUser, IIf(ReturnVal And Returns_IRCNoUser, "No such user in database or online", "User not registered.  Session vHost Set."), "vHost Set"))
End Sub

Private Sub DoUnSet(Setter As String, Nick As String)
If Users.Exists(Nick) Then Call SetDBHost(Users(Nick), "")
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
