Attribute VB_Name = "sMassServ"
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

Public Const ModVersion = "0.0.0.1"

Public Sub MassservHandler(Cmd As String, Sender As Integer)
    Dim SenderNick As String
    
    SenderNick = basFunctions.ReturnUserName(Sender)
    
    
    Dim Parameters As String, FirstSpace As Integer
    FirstSpace = InStr(Cmd, " ")
    Parameters = Right(Cmd, Len(Cmd) - FirstSpace)
    FirstSpace = InStr(Cmd, " ")
    If FirstSpace <> 0 Then Cmd = Left(Cmd, FirstSpace - 1)
    
    If Not basFunctions.IsServicesAdmin(Sender) Then
        Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, Replies.MustBeAServiceAdmin)
        Exit Sub
    End If
    If basFunctions.ReturnUserServicesPermissions(Sender) < 50 Then
        Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, Replies.InsufficientPermissions)
        Exit Sub
    End If
    Select Case UCase(Cmd)
        Case "HELP"
            Call sMassServ.Help(Sender, Parameters)
        Case "VERSION"
            Call sMassServ.Version(Sender)
        Case "SERVJOIN"
            Call sMassServ.sJoin(Sender, Parameters)
        Case "SERVPART"
            Call sMassServ.sPart(Sender, Parameters)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(Sender As Integer, Cmd)
    Dim SenderNick As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "MassServ Commands:")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, " ")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  SERVJOIN     #<chan>        Make all Services bots join a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  SERVPART     #<chan>        Make all Services bots part a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  *ALLBOTJOIN  #<chan>        Make all bots join a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  *ALLBOTPART  #<chan>        Make all bots part a channel")
    'ALLJOIN wont be happening!! Imagine if that was done on a large net!
    'Besides, its irritating.
    'Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  *ALLJOIN     #<chan>        Make all users join a channel")
    'ALLOPERJOIN is a bit invasive... I am thinking about implementing it,
    'but allowing it only to services master/comaster.
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  *ALLOPERJOIN #<chan>        Make all opers join a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  -----------------------------------------")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  *MMODE   #<chan>  <mode>    Mass Mode a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  *MKICK   #<chan>  <reason>  Kick all users from a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  *MINVITE #<chans> #<chand>  Mass Invite all users to a channel")
End Sub

Private Sub Version(Sender As Integer)
    Call basFunctions.SendMessage(basMain.Service(9).Nick, basFunctions.ReturnUserName(Sender), AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(9).Nick & "[" & sMassServ.ModVersion & "]")
End Sub

Private Sub sJoin(Sender As Integer, Channel As String)
    Call basFunctions.JoinServicesToChannel(Sender, Channel)
End Sub

Private Sub sPart(Sender As Integer, Channel As String)
    Call basFunctions.PartServicesFromChannel(Sender, Channel)
End Sub

