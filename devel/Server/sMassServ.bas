Attribute VB_Name = "sMassServ"
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
Public Const ModVersion = "0.0.0.1"

Public Sub MassservHandler(ByVal Cmd As String, ByVal Sender As Integer)

' Explicit ByVals entered: .NET uses ByVal by default, VB6 uses ByRef
' I want any problems with a ByVal definition caught now.

    Dim SenderNick As String
    
    SenderNick = basFunctions.ReturnUserName(Sender)
    
'    Dim Parameters As String, FirstSpace As Integer
'    FirstSpace = InStr(Cmd, " ")
'    Parameters = Right(Cmd, Len(Cmd) - FirstSpace)
'    FirstSpace = InStr(Cmd, " ")
'    If FirstSpace <> 0 Then Cmd = Left(Cmd, FirstSpace - 1)
 ' Darn thats ugly... Im redoing it with Split()
 ' Or, if its not less ugly, Im Bored!
 
    Dim Parameters As String
    If InStr(Cmd, " ") > 0 Then
      Dim CmdParts(0 To 1) As String ' (0 To 1): Yes, I'm paranoid
      CmdParts = Split(Cmd, " ", 2)
      Parameters = CmdParts(1)
      Cmd = CmdParts(0)
    Else
      Parameters = ""
    End If
    
    If Not basFunctions.HasFlag(Sender, AccFlagCanMassServ) Then
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
        Case "OPERJOIN"
            Call sMassServ.OperJoin(Sender, Parameters)
        Case "OPERINVITE"
            Call sMassServ.OperInvite(Sender, Parameters)
        Case "ALLINVITE"
            Call sMassServ.AllInvite(Sender, Parameters)
        Case "MMODE"
            Call sMassServ.MMode(Sender, Parameters)
        Case "MKICK"
            Call sMassServ.MKick(Sender, Parameters)
        Case "MINVITE"
            Call sMassServ.MInvite(Sender, Parameters)
        Case "MKILL"
            If HasFlag(Sender, AccFlagCanMassKill) Then
                Call sMassServ.MKill(Sender, Parameters)
            Else
                Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, Replies.UnknownCommand)
            End If
        Case "CHANKILL"
            If HasFlag(Sender, AccFlagCanMassKill) Then
                Call sMassServ.ChanKill(Sender, Parameters)
            Else
                Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, Replies.UnknownCommand)
            End If
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
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  *ALLBOTJOIN  #<chan>         Make all bots join a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  *ALLBOTPART  #<chan>         Make all bots part a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  OPERJOIN #<chan>            Make all opers join a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  OPERINVITE #<chan>          Invite all opers into a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  ALLINVITE #<chan>           Invite all users into a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  -----------------------------------------")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  MMODE   #<chan>  <mode>     Set a mode on each user on a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  MKICK   #<chan>  <reason>   Kick all users from a channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  MINVITE #<chans> #<chand>   Mass Invite all users in one channel to another")
    If HasFlag(Sender, AccFlagCanMassKill) Then
      ' Begin Mass Kill Commands
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  MKILL <N!U@H> <Reason>      Kill all users matching the specified host")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  CHANKILL #<chan> <Reason>   Kill all users in the specified channel")
    Call basFunctions.SendMessage(basMain.Service(9).Nick, SenderNick, "  *CHANGLINE #<chan> <Reason> G:Line all users in the specified channel")
      ' End Mass Kill Commands
    End If
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

Private Sub OperJoin(Sender As Integer, Channel As String)
Dim l As Integer
For l = LBound(Users) To UBound(Users)
  If Not Users(l).Nick = "" Then
    If InStr(Users(l).Modes, "o") Then
      Call basFunctions.SendData(":" & Service(9).Nick & " INVITE " & Users(l).Nick & " " & Channel)
      Call basFunctions.SendData("SVSJOIN " & Users(l).Nick & " " & Channel)
    End If
  End If
Next l
End Sub

Private Sub OperInvite(Sender As Integer, Channel As String)
Dim l As Integer
For l = LBound(Users) To UBound(Users)
  If Not Users(l).Nick = "" Then
    If InStr(Users(l).Modes, "o") Then
      Call basFunctions.SendData(":" & Service(9).Nick & " INVITE " & Users(l).Nick & " " & Channel)
    End If
  End If
Next l
End Sub

Private Sub AllInvite(Sender As Integer, Channel As String)
Dim l As Integer
For l = LBound(Users) To UBound(Users)
  If Not Users(l).Nick = "" Then
    Call basFunctions.SendData(":" & Service(9).Nick & " INVITE " & Users(l).Nick & " " & Channel)
  End If
Next l
End Sub

Private Sub MMode(Sender As Integer, Parameters As String)
On Local Error GoTo Fail
Dim Chan As String, Mode As String
Chan = basFunctions.ReturnChannelIndex(Split(Parameters, " ")(0))
Mode = Split(Parameters, " ")(1)
Dim l As Integer
For l = LBound(Channels(Chan).Users) To UBound(Channels(Chan).Users)
  Call basFunctions.SendData(":" & Service(0).Nick & " MODE " & Channels(Chan) & " " & Mode & " " & Channels(Chan).Users(l) & " " & Channels(Chan).Users(l) & " " & Channels(Chan).Users(l) & " " & Channels(Chan).Users(l) & " " & Channels(Chan).Users(l) & " " & Channels(Chan).Users(l))
Next l
Fail:
Debug.Print "*** Begin Automated Error Report ***"
Debug.Print "Error " & Err.Number & ": " & Err.Description
Debug.Print "Error Source: " & Err.Source
Debug.Print "*** End Automated Error Report ***"
Stop ' Read your Immediate Window
End Sub

Private Sub MKick(Sender As Integer, Parameters As String)
On Local Error GoTo Fail
Dim Chan As String, Reason As String
Chan = basFunctions.ReturnChannelIndex(Split(Parameters, " ")(0))
Reason = Split(Parameters, " ")(1)
Dim l As Integer
For l = LBound(Channels(Chan).Users) To UBound(Channels(Chan).Users)
  Call basFunctions.SendData(":" & Service(0).Nick & " KICK " & Channels(Chan) & " " & Channels(Chan).Users(l) & ":" & Reason)
Next l
Fail:
Debug.Print "*** Begin Automated Error Report ***"
Debug.Print "Error " & Err.Number & ": " & Err.Description
Debug.Print "Error Source: " & Err.Source
Debug.Print "*** End Automated Error Report ***"
Stop ' Read your Immediate Window
End Sub

Private Sub MInvite(Sender As Integer, Parameters As String)
On Local Error GoTo Fail
Dim SourceChan As String, DestChan As String
SourceChan = basFunctions.ReturnChannelIndex(Split(Parameters, " ")(0))
DestChan = Split(Parameters, " ")(1)
Dim l As Integer
For l = LBound(Channels(SourceChan).Users) To UBound(Channels(SourceChan).Users)
  Call basFunctions.SendData(":" & Service(9).Nick & " INVITE " & Channels(SourceChan).Users(l) & " " & DestChan)
Next l
Fail:
Debug.Print "*** Begin Automated Error Report ***"
Debug.Print "Error " & Err.Number & ": " & Err.Description
Debug.Print "Error Source: " & Err.Source
Debug.Print "*** End Automated Error Report ***"
Stop ' Read your Immediate Window
End Sub

Private Sub MKill(Sender As Integer, Parameters As String)
Dim l As Integer
For l = LBound(Users) To UBound(Users)
  Call basFunctions.SendData("KILL " & Users(l).Nick & " :" & basMain.Service(4).Nick & "!" & basFunctions.ReturnUserName(Sender) & " (" & Parameters & ")")
Next l
End Sub

Private Sub ChanKill(Sender As Integer, Parameters As String)
On Local Error GoTo Fail
Dim Chan As String, Message As String
Chan = basFunctions.ReturnChannelIndex(Split(Parameters, " ")(0))
Message = Split(Parameters, " ")(1)
Dim l As Integer
For l = LBound(Channels(SourceChan).Users) To UBound(Channels(SourceChan).Users)
  Call basFunctions.SendData("KILL " & Channels(SourceChan).Users(l) & " :" & basMain.Service(4).Nick & "!" & basFunctions.ReturnUserName(Sender) & " (" & Message & ")")
Next l
Fail:
Debug.Print "*** Begin Automated Error Report ***"
Debug.Print "Error " & Err.Number & ": " & Err.Description
Debug.Print "Error Source: " & Err.Source
Debug.Print "*** End Automated Error Report ***"
Stop ' Read your Immediate Window
End Sub

'Callin subs for channel mode changes
Public Sub HandlePrefix(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As Integer)

End Sub

Public Sub HandleModeTypeA(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeB(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeC(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)

End Sub

Public Sub HandleModeTypeD(ByVal ChanID As Integer, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleCommand(ByVal Sender As String, ByVal Cmd As String, ByRef Args() As String)

End Sub

Public Sub HandleUserMode(ByVal UserID As Integer, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleTick(ByVal Interval As Single)

End Sub

