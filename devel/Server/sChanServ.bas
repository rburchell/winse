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

Public Sub ChanservHandler(ByVal Cmd As String, ByVal Sender As User)
    Dim Parameters() As String
    Dim SenderNick As String
    
    SenderNick = Sender.Nick
    Parameters() = basFunctions.ParseBuffer(Cmd)
    
    Select Case UCase(Parameters(0))
        Case "REGISTER"
        Case "IDENTIFY"
        Case "ACCESS"
        Case "AKICK", "EXEMPTS", "INVITES"
        Case "INVITE"
        Case "UNBAN"
        Case "VOICE", "DEVOICE", "HALFOP", "DEHALFOP", "OP", "DEOP", "PROTECT", "DEPROTECT", "OWNER", "DEOWNER"
        Case "VOP", "HOP", "AOP", "SOP", "CFOUNDER"
        Case "KICK", "BAN"
        Case "TOPIC"
        Case "MODE"
        Case "SET"
        Case "LOCK"
        Case "UNLOCK"
        Case "DROP"
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

Public Sub Register(ByVal Source As User, ByVal Channel As Channel, ByVal Password As String, ByVal Description As String)

End Sub

Public Sub Identify(ByVal Source As User, ByVal Channel As Channel, ByVal Password As String)

End Sub

Public Sub Access(ByVal Source As User, ByVal Channel As Channel, ByVal Subcommand As String, ByVal Nickname As String, Optional ByVal Flags As String = "")

End Sub

Public Sub ManageMaskList(ByVal Source As User, ByVal Channel As Channel, ByVal List As String, ByVal Subcommand As String, Optional ByVal Entry As String = "")

End Sub

Public Sub Invite(ByVal Source As User, ByVal Channel As Channel, ByVal Nick As User)

End Sub

Public Sub Unban(ByVal Source As User, ByVal Channel As Channel, ByVal User As User)

End Sub

Public Sub StatusChange(ByVal Source As User, ByVal Channel As Channel, ByVal What As String, ByVal Target As User)

End Sub

Public Sub StandardList(ByVal Source As User, ByVal Channel As Channel, ByVal What As String, ByVal Target As String)

End Sub

Public Sub BootUser(ByVal Source As User, ByVal Channel As Channel, ByVal Target As User, ByVal Message As String, Optional ByVal BanType As Byte = -1)

End Sub

Public Sub Topic(ByVal Source As User, ByVal Channel As Channel, ByVal NewTopic As String)

End Sub

Public Sub Mode(ByVal Source As User, ByVal Channel As Channel, ByVal ModeChange As String)

End Sub

Public Sub LockChange(ByVal Source As User, ByVal Channel As Channel, ByVal Locking As Boolean, ByVal SubLock As String, ByVal Entry As String)

End Sub

Public Sub Drop(ByVal Source As User, ByVal Channel As Channel, Optional ByVal ConfirmationCode As String)

End Sub

Private Sub Help(ByVal Sender As User, Cmd)
    Dim SenderNick As String
    SenderNick = Sender.Nick
End Sub

Private Sub Version(Sender As User)
    Call basFunctions.SendMessage(basMain.Service(0).Nick, Sender.Nick, AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(0).Nick & "[" & sNickServ.ModVersion & "]")
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

