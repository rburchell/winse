Attribute VB_Name = "sChanServ"
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
Public Const ModVersion = "0.0.0.2"

Public Sub ChanservHandler(ByVal Cmd As String, ByVal Sender As User)
    Dim Parameters() As String
    Dim SenderNick As String
    
    SenderNick = Sender.Nick
    Parameters() = basFunctions.ParseBuffer(Cmd)
    
    Select Case UCase(Parameters(0))
        Case "ACCESS"
            'ACCESS #thelounge ADD w00t 80
            If UBound(Parameters) < 4 Then
                'insufficient parameters.
            End If
            Call sChanServ.Access(Sender, Parameters)
        Case "REGISTER"
            'REGISTER #thelounge testpass description
            'P[0] - REGISTER
            'P[1] - Name
            'P[2] - Password
            'P[3] - Description
            If UBound(Parameters) < 3 Then
                Call basFunctions.SendMessage(basMain.Service(0).Nick, SenderNick, Replies.InsufficientParameters)
                Exit Sub
            End If
            Dim i As Integer
            For i = 4 To UBound(Parameters)
                Parameters(3) = Parameters(3) & " " & Parameters(i)
            Next i
            Call sChanServ.Register(Sender, Parameters(1), Parameters(2), Parameters(3))
        Case "HELP"
            'P[0] - HELP
            'P[1]> - Word
            If UBound(Parameters) <> 0 Then
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

Private Sub Help(ByVal Sender As User, Cmd)
    Dim SenderNick As String
    SenderNick = Sender.Nick
    Select Case UCase(Cmd)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(0).Nick, SenderNick, "ChanServ Commands:")
            Call basFunctions.SendMessage(basMain.Service(0).Nick, SenderNick, " REGISTER")
            Call basFunctions.SendMessage(basMain.Service(0).Nick, SenderNick, " ACCESS")
    End Select
End Sub

Private Sub Version(Sender As User)
    Call basFunctions.SendMessage(basMain.Service(0).Nick, Sender.Nick, AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(0).Nick & "[" & sNickServ.ModVersion & "]")
End Sub

Private Sub Access(Sender As User, Parameters() As String)
    'ACCESS #thelounge ADD w00t 80
    'Check if the chan is registered first.
    If Channels.Exists(Parameters(1)) = False Then
        Call basFunctions.NotifyAllUsersWithServicesAccess(Replies.SanityCheckLostChannel)
        Exit Sub
    End If
    If Not basFunctions.IsChanRegistered(Parameters(1)) Then
        'chan not registered.
        Call basFunctions.SendMessage(basMain.Service(0).Nick, basMain.Users(Sender).Nick, Replace(Replies.ChanServChannelNotRegistered, "%n", Parameters(1)))
        Exit Sub
    End If
    
    Select Case Parameters(2)
        Case "ADD"
        Case "DEL"
    End Select
End Sub

Private Sub Register(Sender As User, ChannelToRegister As String, Password As String, Description As String)
    ChannelToRegister = UCase(ChannelToRegister)
    'We need to check for registration here.
    Dim ChanIndex As Channel
    Set ChanIndex = Channels(ChannelToRegister)
    If ChanIndex Is Nothing Then
        'This is a Bad Thing.
        Call basFunctions.NotifyAllUsersWithServicesAccess(Replies.SanityCheckLostChannel)
        'For the sake of not proceeding on with an
        'invalid index... - aquanight
        Exit Sub '!!!
        'Alternatively, we can RTE. - aquanight
            'Dear god, did I really forget that Exit?? *checks old code* Oops. --w00t
    End If

    With basMain.Channels(ChanIndex)
        Call basFileIO.SetInitEntry(App.Path & "\databases\channels.db", ChannelToRegister, "Topic", "Registered by " & basMain.Users(Sender).Nick)
        Call basFileIO.SetInitEntry(App.Path & "\databases\channels.db", ChannelToRegister, "TopicSetBy", basMain.Service(0).Nick)
        Call basFileIO.SetInitEntry(App.Path & "\databases\channels.db", ChannelToRegister, "Founder", basMain.Users(Sender).Nick)
        Call basFileIO.SetInitEntry(App.Path & "\databases\channels.db", ChannelToRegister, "FounderPassword", Password)
        Call basFileIO.SetInitEntry(App.Path & "\databases\channels.db", ChannelToRegister, "MLock", "+ntr")
    End With
    Dim TotalRegisteredChannels As Variant
    TotalRegisteredChannels = CDec(basFileIO.GetInitEntry(App.Path & "\databases\index.db", "Totals", "TotalRegisteredChannels", -1))
    TotalRegisteredChannels = CStr(TotalRegisteredChannels + 1)
    Call basFileIO.SetInitEntry(App.Path & "\databases\index.db", "Totals", "TotalRegisteredChannels", CStr(TotalRegisteredChannels))
    Call basFileIO.SetInitEntry(App.Path & "\databases\index.db", "Channels", "RegisteredChannel" & TotalRegisteredChannels, ChannelToRegister)
    
    'Channel registered. Get cs to set the topic :P
    Call basFunctions.SendData(":" & basMain.Service(0).Nick & " TOPIC " & ChannelToRegister & " :Registered by " & basMain.Users(Sender).Nick)
    'now get cs to set the modes yay
    'Putting +nt isn't a good idea IMHO. The chanop
    'may not want this behavior :P . I'm not gonna
    'change it right away, though, since no channel in
    'their right mind would run without +n (dunno about
    '+t). Assuming everyone is in the right mind,
    'however, is just plain stupid :P - aquanight
        'It will be configurable eventually when I get around to it. Too much coding, too little time.
        '--w00t
    basFunctions.SendData (":" & basMain.Service(0).Nick & " MODE " & ChannelToRegister & " :+ntr")
End Sub

'Callin subs for channel mode changes
Public Sub HandlePrefix(ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As User)

End Sub

Public Sub HandleModeTypeA(ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeB(ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeC(ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)

End Sub

Public Sub HandleModeTypeD(ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleCommand(ByVal Sender As String, ByVal Cmd As String, ByRef Args() As String)

End Sub

Public Sub HandleUserMode(ByVal User As User, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleTick(ByVal Interval As Single)

End Sub

