Attribute VB_Name = "sChanServ"
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

Public Const ModVersion = "0.0.0.2"

Public Sub ChanservHandler(Cmd As String, Sender As Integer)
    Dim SenderNick As String
    Dim Parameters() As String
    Dim Description As String
    ReDim Parameters(0) As String
    
    SenderNick = basFunctions.ReturnUserName(Sender)
    Dim Cmdcopy As String, Spacer As Long, Elements As Long
    Cmdcopy = Cmd
    Do While InStr(Cmdcopy, " ") <> 0
        Spacer = InStr(Cmdcopy, " ")
        If Spacer <> 0 Then
            Parameters(Elements) = Left(Cmdcopy, Spacer - 1)
        Else
            Parameters(Elements) = Cmdcopy
        End If
        Cmdcopy = Right(Cmdcopy, Len(Cmdcopy) - Spacer)
        Elements = Elements + 1
        ReDim Preserve Parameters(Elements) As String
    Loop
    Parameters(Elements) = Cmdcopy
    
    Select Case UCase(Parameters(0))
        Case "REGISTER"
            'REGISTER #thelounge testpass description
            'P[0] - REGISTER
            'P[1] - Name
            'P[2] - Password
            'P[3] - Description
            If Elements < 3 Then
                Call basFunctions.SendMessage(basMain.Service(0).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Description = Parameters(3)
            Dim i As Integer
            For i = 4 To Elements
                Description = Description & " " & Parameters(i)
            Next i
            Call sChanServ.Register(Sender, Parameters(1), Parameters(2), Description)
        Case "HELP"
            'P[0] - HELP
            'P[1]> - Word
            If Elements <> 0 Then
                Call sChanServ.Help(Sender, Parameters(1))
            Else
                Call sChanServ.Help(Sender, "")
            End If
        Case "VERSION"
            'P[0] - VERSION
            Call sChanServ.Version(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(0).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Private Sub Help(Sender As Integer, Cmd)
    Dim SenderNick As String
    SenderNick = basFunctions.ReturnUserName(Sender)
    Select Case UCase(Cmd)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(0).Nick, SenderNick, "ChanServ Commands:")
            Call basFunctions.SendMessage(basMain.Service(0).Nick, SenderNick, " REGISTER")
    End Select
End Sub

Private Sub Version(Sender As Integer)
    Call basFunctions.SendMessage(basMain.Service(0).Nick, basFunctions.ReturnUserName(Sender), AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(0).Nick & "[" & sNickServ.ModVersion & "]")
End Sub

Private Sub Register(Sender As Integer, ChannelToRegister As String, Password As String, Description As String)
    ChannelToRegister = UCase(ChannelToRegister)
    'We need to check for registration here.
    Dim ChanIndex As Integer
    ChanIndex = basFunctions.ReturnChannelIndex(ChannelToRegister)
    If ChanIndex = -1 Then
        ' :| This should NEVER EVER HAPPEN! If it does, a services restart
        'should really be required!!! (hopefully, we never get this far :P)
        Call basFunctions.NotifyAllUsersWithServicesAccess("CHANSERV: Sanity check! We lost a channel in the array! aaaargh!!!! Advise a restart!")
        'For the sake of not proceeding on with an
        'invalid index... - aquanight
        Exit Sub '!!!
        'Alternatively, we can RTE. - aquanight
    End If

    With basMain.Channels(ChanIndex)
        Call basFileIO.SetInitEntry("channels.db", ChannelToRegister, "Topic", "Registered by " & basMain.Users(Sender).Nick)
        Call basFileIO.SetInitEntry("channels.db", ChannelToRegister, "TopicSetBy", basMain.Service(0).Nick)
        Call basFileIO.SetInitEntry("channels.db", ChannelToRegister, "Founder", basMain.Users(Sender).Nick)
        Call basFileIO.SetInitEntry("channels.db", ChannelToRegister, "FounderPassword", Password)
        Call basFileIO.SetInitEntry("channels.db", ChannelToRegister, "MLock", "+ntr")
    End With
    Dim TotalRegisteredChannels As Variant
    TotalRegisteredChannels = CDec(basFileIO.GetInitEntry("index.db", "Totals", "TotalRegisteredChannels", -1))
    TotalRegisteredChannels = CStr(TotalRegisteredChannels + 1)
    Call basFileIO.SetInitEntry("index.db", "Totals", "TotalRegisteredChannels", CStr(TotalRegisteredChannels))
    Call basFileIO.SetInitEntry("index.db", "Channels", "RegisteredChannel" & TotalRegisteredChannels, ChannelToRegister)
    
    'Channel registered. Get cs to set the topic :P
    Call basFunctions.SendData(":ChanServ TOPIC " & ChannelToRegister & " :Registered by " & basMain.Users(Sender).Nick)
    'now get cs to set the modes yay
    'Putting +nt isn't a good idea IMHO. The chanop
    'may not want this behavior :P . I'm not gonna
    'change it right away, though, since no channel in
    'their right mind would run without +n (dunno about
    '+t). Assuming everyone is in the right mind,
    'however, is just plain stupid :P - aquanight
    basFunctions.SendData (":ChanServ MODE " & ChannelToRegister & " :+ntr")
End Sub
