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

'Access Flags
'Access flags marked NEGATIVE NEVER require an IDENTIFY to take effect, regardless of the SECURE option.
Public Const CHANSERV_PERMFOUNDER = "F" 'Permanent Founder.
Public Const CHANSERV_COFOUNDER = "f"   'Temporary or Co-Founder.
Public Const CHANSERV_ACLREAD = "a"     'Read-Only access to ACL.
Public Const CHANSERV_ACLRW = "A"       'Read-Write access to ACL.
Public Const CHANSERV_VOICE = "v"       'May (DE)VOICE self.
Public Const CHANSERV_VOICEOP = "V"     'May (DE)VOICE anyone.
Public Const CHANSERV_QUIET = "q"       'May not be voiced. NEGATIVE
Public Const CHANSERV_SUPERQUIET = "Q"  'UnrealIRCd Only. May not be voiced, and is ~q/~n banned on join.
                                        'For non-Unreal, just remaps to +q. NEGATIVE
Public Const CHANSERV_HALFOP = "h"      'May (DE)HALFOP self.
Public Const CHANSERV_HALFOPOP = "H"    'May (DE)HALFOP anyone.
Public Const CHANSERV_DEHALFOP = "D"    'May not be halfopped (+h). NEGATIVE
Public Const CHANSERV_OP = "o"          'May (DE)OP self.
Public Const CHANSERV_OPOP = "O"        'May (DE)OP anyone.
Public Const CHANSERV_DEOP = "d"        'May not be opped. NEGATIVE
Public Const CHANSERV_PROTECT = "p"     'UnrealIRCd: May (DE)PROTECT self.
                                        'Others: ChanServ will enforce protection on this user.
Public Const CHANSERV_PROTECTOP = "P"   'UnrealIRCd: May (DE)PROTECT anyone.
                                        'Others: ChanServ will enforce protection on this user.
Public Const CHANSERV_OWNER = "n"       'UnrealIRCd: May (DE)OWNER self.
                                        'Others: ChanServ will enforce greater protection on this user.
Public Const CHANSERV_OWNEROP = "N"     'UnrealIRCd: May (DE)ONWER anyone.
                                        'Others: ChanServ will enforce greater protection on this user.
Public Const CHANSERV_CANKICK = "k"     'May use CHANSERV KICK.
Public Const CHANSERV_AUTOKICK = "K"    'Not allowed to join - is kicked and banned on join. NEGATIVE
Public Const CHANSERV_CANBAN = "b"      'May use CHANSERV BAN.
Public Const CHANSERV_BANOP = "B"       'Has read-write access to the AKICK list.
Public Const CHANSERV_EXEMPT = "e"      'Is exempt from AKICK checking, and ChanServ will +e this user
                                        'before placing any ban that matches him.
Public Const CHANSERV_EXEMPTOP = "E"    'Has read-write access to the EXEMPT list.
Public Const CHANSERV_INVITE = "i"      'May use CHANSERV INVITE on self.
Public Const CHANSERV_INVITEOP = "I"    'May use CHANSERV INVITE on anyone. May also manage the INVITE list.
Public Const CHANSERV_MODEOP = "m"      'May use CHANSERV MODE command.
Public Const CHANSERV_CLEAR = "c"       'May use CHANSERV CLEAR. Suboption permissions depend on other flags.
Public Const CHANSERV_TOPICOP = "t"     'May use CHANSERV TOPIC.
Public Const CHANSERV_TOPICMAN = "T"    'May give/take +t flag.
Public Const CHANSERV_GETKEY = "g"      'May use CHANSERV GETKEY.
Public Const CHANSERV_SETKEY = "G"      'May give/take +g flag. May use CHANSERV SETKEY.
Public Const CHANSERV_UNBAN = "u"       'May use CHANSERV UNBAN.
Public Const CHANSERV_UNBANOP = "U"     'May give/take +u flag.
Public Const CHANSERV_MEMOADMIN = "M"   'May send MEMOs to the channel. If +privatememos, may read memos.
Public Const CHANSERV_BOTCOMS = "C"     'May use BotServ !commands.
Public Const CHANSERV_BOTMODIFY = "x"   'May use BotServ SET, KICK, and BADWORDS.
Public Const CHANSERV_BOTSPEAK = "X"    'May use BotServ SAY and ACT.
Public Const CHANSERV_SHOWGREET = "y"   'Channel bot will print user's GREET message on join.
Public Const CHANSERV_BOTNOKICK = "Y"   'Immune to Bot Kickers.
Public Const CHANSERV_INFOALL = "z"     'Allowed to get ALL INFO.
Public Const CHANSERV_NOSIGNKICK = "Z"  'KICK or BAN usage is not signed or prefixed.
Public Const CHANSERV_SET = "s"         'May use SET except LOCKed options.
Public Const CHANSERV_SETLOCK = "S"     'May use (UN)LOCK SET. May UNLOCK and SET options LOCKed by +S's.
                                        '(May NOT UNLOCK or SET an option locked by a +f or the +F.)
Public Const CHANSERV_LOCKACE = "l"     'May use (UN)LOCK ACCESS.
Public Const CHANSERV_LOCKLIST = "L"    'May use (UN)LOCK AKICK/EXEMPT/INVITE.
'(Note: Only +f or +F may lock an entire list. +l and +L can only lock single entries, and only entries
'of a lower level than them.)

'Default flag mappings:
Public Const CHANSERV_VOPDEFAULT = "vyiua"
Public Const CHANSERV_HOPDEFAULT = "hVkbiugta"
Public Const CHANSERV_AOPDEFAULT = "oOHVkbeiugtma"
Public Const CHANSERV_SOPDEFAULT = "pOHVkbeiugTsMcBEIaAm"
Public Const CHANSERV_CFOUNDERDEFAULT = "f"

'Structure of each channel record:
'Each channel requires 2 records: one will be used for the access list.
'Channel Settings Record:
'Record Name is the name of the channel.
'Fields:
'DESC | Channel Description
'PASSWORD | Channel Password
'List item prefixes:
'- : Normal.
'$ : Sticky.
'@ : Lock.
'! : CoFounder Lock.
'# : Founder Lock.
'AKICK | Space seperated list of autokick entries.
'EXEMPT | Space seperated list of exempt entries.
'INVITE | Space seperated list of invite entries.
'SUCCESSOR | Successor's nick.
'SECUREOPS | ON/OFF (Non ACL members are +d)
'SECUREHALFOPS | ON/OFF (Non ACL members are +D)
'SECUREVOICES | ON/OFF (Non ACL members are +q)
'RESTRICTED | ON/OFF (Non ACL members are +K)
'SECURE | ON/OFF
'LEAVEOPS | ON/OFF (First joiner isn't deopped, or netjoin ops aren't reversed.)
'TOPICLOCK | ON/OFF
'STRICTSTATUS | ON/OFF
'STRICTLISTS | ON/OFF
'LEARNBANS | ON/OFF/Number
'FORGETBANS | ON/OFF
'GIVE | ON/OFF
'STRICTMODES | ON/OFF
'MLOCK | [[[+|-]<unparameteredmode>]] [[[+]<parameteredmode(s)> <param(s)>]]
'LOCK SET: Space seperated list of locked SET options. Prefix ! for +f lock, # for +F lock.
'LOCK ACCESS: Space seperated list of locked ACEs (by nick). Prefix ! for +f lock, # for +F lock.
'BOTS | Space seperated list of BotServ bots assigned to this channel.
'BOTKICK | Nick of an assigned bot responsible for issuing requested KICKs.
'BOTAUTOMODE | Nick of an assigned bot responsible for automatic mode setting (for +b, +o, etc).
'BOTMODE | Nick of an assigned bot responsible for requested mode changes.
'BOTTOPIC | Nick of an assigned bot responsible for TOPIC changes.
'BOTGREET | Nick of an assigned bot responsible for saying GREET messages.
'BOTAUTOKICK | Nick of an assigned bot responsible for issuing automatic KICKs.

'Channel Access Record:
'Record Name is "%s ACCESS LIST"
'Fields are named by nickname, and value is flags.

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

