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
Public Const CHANSERV_VOPDEFAULT = CHANSERV_VOICE + CHANSERV_SHOWGREET + CHANSERV_INVITE + CHANSERV_UNBAN + CHANSERV_ACLREAD
    '"vyiua"
Public Const CHANSERV_HOPDEFAULT = CHANSERV_VOPDEFAULT + CHANSERV_HALFOP + CHANSERV_VOICEOP + CHANSERV_CANKICK + CHANSERV_CANBAN + CHANSERV_GETKEY + CHANSERV_TOPICOP
    '"vyiuahVkbgt"
Public Const CHANSERV_AOPDEFAULT = CHANSERV_HOPDEFAULT + CHANSERV_HALFOPOP + CHANSERV_OP + CHANSERV_OPOP + CHANSERV_EXEMPT + CHANSERV_MODEOP
    '"vyiuahVkbgtHoOem"
Public Const CHANSERV_SOPDEFAULT = CHANSERV_AOPDEFAULT + CHANSERV_PROTECT + CHANSERV_TOPICMAN + CHANSERV_SET + CHANSERV_MEMOADMIN + CHANSERV_CLEAR + CHANSERV_BANOP + CHANSERV_EXEMPTOP + CHANSERV_INVITEOP + CHANSERV_ACLRW
    '"vyiuahVkbgtHoOempTsMcBEIA"
Public Const CHANSERV_CFOUNDERDEFAULT = CHANSERV_COFOUNDER + CHANSERV_OWNER
    '"fn"

Public DB As Collection

'These two are important!!!
Public Sub LoadData(ByVal conn As Connection)
    Set DB = ReadTableIntoCollection(conn, "ChanServ")
    Dim idx As Long, subcol As Collection
    'Key each subcollection under it's Name index.
    For idx = 1 To DB.Count
        Set subcol = DB(idx)
        DB.Remove idx
        DB.Add subcol, subcol("Name")
        'We should add founder checks here, but I won't do that until DB access is STABLE.
    Next idx
End Sub

Public Sub SaveData(ByVal conn As Connection)
    'Great. Now we're writing to the database. This aint as easy :| .
    Dim rs As Recordset
    Set rs = GetTable(conn, "ChanServ")
    'Prepare the fields array in advance.
    Dim Fields(0 To 50) As String
    Fields(0) = "name"
    Fields(1) = "password"
    Fields(2) = "description"
    Fields(3) = "suspended"
    Fields(4) = "successor"
    Fields(5) = "access_list"
    Fields(6) = "akicks"
    Fields(7) = "exempts"
    Fields(8) = "invites"
    Fields(9) = "secure_ops"
    Fields(10) = "secure_half_ops"
    Fields(11) = "secure_voices"
    Fields(12) = "restricted"
    Fields(13) = "secure"
    Fields(14) = "leave_ops"
    Fields(15) = "topic_lock"
    Fields(16) = "strict_status"
    Fields(17) = "strict_list"
    Fields(18) = "learn_bans"
    Fields(19) = "forget_bans"
    Fields(20) = "give"
    Fields(21) = "strict_mode"
    Fields(22) = "mlock"
    Fields(23) = "last_topic"
    Fields(24) = "topic_set_by"
    Fields(25) = "topic_set_on"
    Fields(26) = "time_registered"
    Fields(27) = "last_join"
    Fields(28) = "bots"
    Fields(29) = "bot_kick"
    Fields(30) = "bot_mode"
    Fields(31) = "bot_topic"
    Fields(32) = "bot_greet"
    Fields(33) = "bot_auto_kick"
    Fields(34) = "bot_auto_mode"
    Fields(35) = "no_kick_ops"
    Fields(36) = "no_kick_voice"
    Fields(37) = "no_bot"
    Fields(38) = "kick_bold"
    Fields(39) = "kick_bad_words"
    Fields(40) = "kick_caps"
    Fields(41) = "kick_color"
    Fields(42) = "kick_flood"
    Fields(43) = "kick_repeat"
    Fields(44) = "kick_reverse"
    Fields(45) = "kick_underlines"
    Fields(46) = "kick_caps_minimum"
    Fields(47) = "kick_caps_trigger"
    Fields(48) = "kick_flood_lines"
    Fields(49) = "kick_flood_duration"
    Fields(50) = "kick_repeat_count"
    Fields(51) = "kick_bw_list"
    Dim vals As Variant
    With rs
        Dim subcol As Collection
        For Each subcol In DB
            .MoveFirst
            .Find "Name=" & subcol("Name")
            If .BOF Or .EOF Then
                'Channel was registered since last update, so we need to create it.
                vals = CollToArray(subcol, Fields)
                .AddNew Fields, vals
                .Update
            Else
                'Channel was previously registered, in which case we are pointing to a valid record.
                vals = CollToArray(subcol, Fields)
                .Update Fields, vals
            End If
        Next subcol
        'Now we need to look for channels in the database that we don't have in the collection - these
        'were dropped between updates, so we need to remove them from the DB or they get mysteriously
        'reregistered :) .
        .MoveFirst
        While Not .EOF
            'Now see if the current record is in our memory cache.
            On Error Resume Next
            Set subcol = DB(.Fields("Name"))
            If Err.Number = 9 Then
                'Not found.
                Err.Clear
                .Delete 'Delete this record. Note that this doesn't move the record-pointer, which means
                        'any read or write operation will fail. We have to use Move*/Seek/Find/Close/etc
                        'before we can safely do stuff again. Thankfully we don't need to do anything else
                        'but just think of this as a warning in case you need to .Delete in other code.
            End If
            .MoveNext 'A deleted record is fully released here :) . This means that MovePrevious won't put
                      'us back on strange-deleted-record-land. Example: if we .MoveFirst then .Delete,
                      'MoveNext and MoveFirst would have the same result. Thus, we could theoretically
                      'clear a table by looping around .MoveFirst and .Delete :) .
        Wend
    End With
End Sub

Public Sub ChanservHandler(ByVal Cmd As String, ByVal Sender As User)
    Dim Parameters() As String
    Dim SenderNick As String
    
    SenderNick = Sender.Nick
    Parameters() = basFunctions.ParseBuffer(Cmd)
    
    Select Case UCase(Parameters(0))
        Case "REGISTER"
            'REGISTER <channel> <pass> <desc>
            If UBound(Parameters) < 3 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServRegEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            Else
                Register Sender, Channels(Parameters(1)), Parameters(2), Split(Cmd, " ", 4)(3)
            End If
        Case "IDENTIFY"
            'IDENTIFY <channel> <pass>
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            Else
                Identify Sender, Channels(Parameters(1)), Parameters(2)
            End If
        Case "ACCESS"
            'ACCESS <channel> {ADD|DEL|SET|LIST} <nick> <flags>
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            ElseIf Parameters(2) = "SET" Or Parameters(2) = "ADD" Then
                If UBound(Parameters) < 4 Then
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
                Else
                    Access Sender, Channels(Parameters(1)), Parameters(2), Parameters(3), Parameters(4)
                End If
            ElseIf Parameters(2) = "DEL" Then
                If UBound(Parameters) < 3 Then
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
                Else
                    Access Sender, Channels(Parameters(1)), Parameters(2), Parameters(3)
                End If
            ElseIf Parameters(2) = "LIST" Then
                Access Sender, Channels(Parameters(1)), Parameters(2)
            Else
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.UnknownSubCommand, "%c", Parameters(0)))
            End If
        Case "AKICK", "EXEMPTS", "INVITES"
            'AKICK <channel> {ADD|DEL|LIST|VIEW|STICK|UNSTICK} <nick or mask> [<reason>]
            'EXEMPTS <channel> {ADD|DEL|LIST|VIEW|STICK|UNSTICK} <nick or mask>
            'INVITES <channel> {ADD|DEL|LIST|VIEW|STICK|UNSTICK} <nick or mask>
            'NOTE: If the IRCd doesn't support invite lists, INVITES STICK AND UNSTICK DO NOT WORK.
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            Else
                Select Case Parameters(2)
                    Case "ADD", "DEL", "STICK", "UNSTICK"
                        If UBound(Parameters) < 3 Then
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
                        ElseIf UBound(Parameters) = 3 Then
                            ManageMaskList Sender, Channels(Parameters(1)), Parameters(0), Parameters(2), Parameters(3)
                        ElseIf UBound(Parameters) >= 4 Then
                            ManageMaskList Sender, Channels(Parameters(1)), Parameters(0), Parameters(2), Parameters(3), Split(Cmd, " ", 5)(4)
                        End If
                    Case "VIEW", "LIST"
                        ManageMaskList Sender, Channels(Parameters(1)), Parameters(0), Parameters(2)
                    Case Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.UnknownSubCommand, "%c", Parameters(0)))
                    'End Case
                End Select
            End If
        Case "INVITE"
            'INVITE <channel> [<nick>]
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            ElseIf UBound(Parameters) = 1 Then
                Invite Sender, Channels(Parameters(1)), Sender
            ElseIf Not Users.Exists(Parameters(2)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.UserDoesntExist)
                Call basFunctions.SendNumeric(SenderNick, 401, Parameters(2) & " :No such nick/channel")
            Else
                Invite Sender, Channels(Parameters(1)), Users(Parameters(2))
            End If
        Case "UNBAN"
            'UNBAN <channel> [<nick>]
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            ElseIf UBound(Parameters) = 1 Then
                Invite Sender, Channels(Parameters(1)), Sender
            ElseIf Not Users.Exists(Parameters(2)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.UserDoesntExist)
                Call basFunctions.SendNumeric(SenderNick, 401, Parameters(2) & " :No such nick/channel")
            Else
                Unban Sender, Channels(Parameters(1)), Users(Parameters(2))
            End If
        Case "VOICE", "DEVOICE", "HALFOP", "DEHALFOP", "OP", "DEOP", "PROTECT", "DEPROTECT", "OWNER", "DEOWNER"
            '[DE]{VOICE|[HALF]OP|PROTECT|OWNER} <channel> <nick>
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            ElseIf UBound(Parameters) = 1 Then
                Invite Sender, Channels(Parameters(1)), Sender
            ElseIf Not Users.Exists(Parameters(2)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.UserDoesntExist)
                Call basFunctions.SendNumeric(SenderNick, 401, Parameters(2) & " :No such nick/channel")
            Else
                StatusChange Sender, Channels(Parameters(1)), Parameters(0), Users(Parameters(2))
            End If
        Case "VOP", "HOP", "AOP", "SOP", "CFOUNDER"
            '{{V|H|A|S}OP|CFOUNDER} <channel> ADD <nick>
            If UBound(Parameters) < 3 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            ElseIf Parameters(2) <> "ADD" Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.UnknownSubCommand, "%c", Parameters(0)))
            ElseIf Not Users.Exists(Parameters(3)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.UserDoesntExist)
                Call basFunctions.SendNumeric(SenderNick, 401, Parameters(2) & " :No such nick/channel")
            Else
                StandardList Sender, Channels(Parameters(1)), Parameters(0), Users(Parameters(2))
            End If
        Case "KICK", "BAN"
            '{KICK|BAN} <channel> [<nick> [<type>] [<reason>]]
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            ElseIf UBound(Parameters) = 1 Then
                BootUser Sender, Channels(Parameters(1)), Sender, "Requested", IIf(Parameters(0) = "BAN", 0, -1)
            ElseIf Not Users.Exists(Parameters(2)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.UserDoesntExist)
                Call basFunctions.SendNumeric(SenderNick, 401, Parameters(2) & " :No such nick/channel")
            ElseIf UBound(Parameters) = 2 Then
                BootUser Sender, Channels(Parameters(1)), Users(Parameters(2)), "Requested", IIf(Parameters(0) = "BAN", 0, -1)
            ElseIf Parameters(0) = "BAN" Then
                If IsNumeric(Parameters(3)) Then
                    If UBound(Parameters) >= 4 Then
                        BootUser Sender, Channels(Parameters(1)), Users(Parameters(2)), Split(Cmd, " ", 5)(4), Parameters(3)
                    Else
                        BootUser Sender, Channels(Parameters(1)), Users(Parameters(2)), "Requested", Parameters(3)
                    End If
                Else
                    BootUser Sender, Channels(Parameters(1)), Users(Parameters(2)), Split(Cmd, " ", 4)(3), 0
                End If
            ElseIf Parameters(0) = "KICK" Then
                BootUser Sender, Channels(Parameters(1)), Users(Parameters(2)), Split(Cmd, " ", 4)(3), -1
            End If
        Case "TOPIC"
            'TOPIC <channel> <newtopic>
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            Else
                Topic Sender, Channels(Parameters(1)), Split(Cmd, " ", 3)(2)
            End If
        Case "MODE"
            'MODE <channel> <modechange>
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            Else
                Mode Sender, Channels(Parameters(1)), Split(Cmd, " ", 3)(2)
            End If
        Case "SET"
            'SET <channel> <setting>
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            Else
                ChannelSetting Sender, Channels(Parameters(1)), Split(Cmd, " ", 3)(2)
            End If
        Case "LOCK"
            'LOCK <channel> [SET|AKICK|EXEMPTS|INVITE|ACCESS] [<entry>]
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            ElseIf UBound(Parameters) = 2 Then
                LockChange Sender, Channels(Parameters(1)), True, Parameters(2)
            Else
                LockChange Sender, Channels(Parameters(1)), True, Parameters(2), Parameters(3)
            End If
        Case "UNLOCK"
            'UNLOCK <channel> [SET|AKICK|EXEMPTS|INVITE|ACCESS] [<entry>]
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            ElseIf UBound(Parameters) = 2 Then
                LockChange Sender, Channels(Parameters(1)), False, Parameters(2)
            Else
                LockChange Sender, Channels(Parameters(1)), False, Parameters(2), Parameters(3)
            End If
        Case "DROP"
            'DROP <channel> [<confirmation>]
            If UBound(Parameters) < 1 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            ElseIf UBound(Parameters) = 1 Then
                Drop Sender, Channels(Parameters(1))
            Else
                Drop Sender, Channels(Parameters(1)), Parameters(2)
            End If
        Case "FORBID"
            'FORBID <channel> <reason>
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            Else
                Forbid Sender, Channels(Parameters(1)), Split(Cmd, " ", 3)(2)
            End If
        Case "SUSPEND"
            'SUSPEND <channel> <reason>
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            Else
                Suspend Sender, Channels(Parameters(1)), Split(Cmd, " ", 3)(2)
            End If
        Case "UNSUSPEND"
            'UNSUSPEND <channel>
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            Else
                Unsuspend Sender, Channels(Parameters(1))
            End If
        Case "HELP"
            'P[0] - HELP
            'P[1]> - Word
            If UBound(Parameters) <> 0 Then
                Call sChanServ.Help(Sender, Split(Cmd, " ", 2)(1))
            Else
                Call sChanServ.Help(Sender, "")
            End If
        Case "VERSION"
            'P[0] - VERSION
            Call sChanServ.Version(Sender)
        Case Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.UnknownCommand)
    End Select
End Sub

Public Sub Register(ByVal Source As User, ByVal channel As channel, ByVal Password As String, ByVal Description As String)
    'Now, first thing is, can we register this channel?
    'Conditions for registration:
    '- Channel isn't #
    '- Channel isn't "do not register"
    '- Channel isn't forbidden or suspended.
    '- Channel isn't an official channel listed in the configuration (Help, Operations, Debug).
    If channel.Name = "#" Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServCantReg, "%s", "Null channel cannot be registered."), "%c", channel.Name))
    ElseIf CollectionContains(DB, channel.Name) Then
        'It's already registered.
        If DB(channel.Name)("suspended") And DB(channel.Name)("password") = "" Then
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServCantReg, "%s", "Channel is forbidden"), "%c", channel.Name))
        Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServAlreadyRegd, "%c", channel.Name))
        End If
    'TODO: Add Help/Operations/Debug channel checks?
    ElseIf Not channel.Members.Exists(Source.Nick) Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServRegNeedOps, "%c", channel.Name))
        Call basFunctions.SendNumeric(Source.Nick, 482, channel.Name & " :You're not channel operator.")
    ElseIf InStr(channel.Members(Source.Nick).Modes, "o") = 0 And InStr(channel.Members(Source.Nick).Modes, "a") = 0 And InStr(channel.Members(Source.Nick).Modes, "q") = 0 Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServRegNeedOps, "%c", channel.Name))
        Call basFunctions.SendNumeric(Source.Nick, 482, channel.Name & " :You're not channel operator.")
    ElseIf Not Source.IdentifiedToNick = "" Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.ChanServYouArentRegistered)
    Else
        'Otherwise, we're okay to register.
        Dim newcol As Collection, nTime As Double
        nTime = basUnixTime.GetTime()
        Set newcol = New Collection
        newcol.Add channel.Name, "name"
        newcol.Add False, "suspended"
        newcol.Add Password, "password"
        newcol.Add Description, "description"
        newcol.Add "", "successor"
        newcol.Add Source.Nick & " F", "access_list"
        newcol.Add False, "secure_ops"
        newcol.Add False, "secure_halfops"
        newcol.Add False, "secure_voices"
        newcol.Add False, "restricted"
        newcol.Add False, "secure"
        newcol.Add False, "leave_ops"
        newcol.Add False, "topic_lock"
        newcol.Add False, "strict_status"
        newcol.Add False, "strict_list"
        newcol.Add False, "learn_bans"
        newcol.Add False, "forget_bans"
        newcol.Add False, "give"
        newcol.Add False, "strict_mode"
        newcol.Add "+nt", "mlock"
        newcol.Add "This channel has been registered.", "last_topic"
        newcol.Add Service(SVSINDEX_CHANSERV).Nick, "topic_set_by"
        newcol.Add nTime, "topic_set_on"
        newcol.Add nTime, "time_registered"
        newcol.Add nTime, "last_join"
        newcol.Add "!" & Service(SVSINDEX_CHANSERV).Nick, "bots"
        newcol.Add Null, "bot_kick"
        newcol.Add Null, "bot_mode"
        newcol.Add Null, "bot_topic"
        newcol.Add Null, "bot_greet"
        newcol.Add Null, "bot_auto_kick"
        newcol.Add Null, "bot_auto_mode"
        newcol.Add False, "no_kick_ops"
        newcol.Add False, "no_kick_voices"
        newcol.Add False, "no_bot"
        newcol.Add -1, "kick_bold"
        newcol.Add -1, "kick_bad_words"
        newcol.Add -1, "kick_caps"
        newcol.Add -1, "kick_color"
        newcol.Add -1, "kick_flood"
        newcol.Add -1, "kick_repeat"
        newcol.Add -1, "kick_reverse"
        newcol.Add -1, "kick_underline"
        newcol.Add 5, "kick_caps_minimum"
        newcol.Add 10, "kick_caps_trigger"
        newcol.Add 5, "kick_flood_lines"
        newcol.Add 10, "kick_flood_duration"
        newcol.Add 3, "kick_repeat_count"
        newcol.Add "", "kick_bw_list"
        'Now do what we need to do :).
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServREGISTEROK, "%c", channel.Name))
    End If
End Sub

Public Sub Identify(ByVal Source As User, ByVal channel As channel, ByVal Password As String)
    If Not IsChanRegistered(channel.Name) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", channel.Name))
    'Already identified, or already has cofounder access?
    ElseIf CollectionContains(channel.IdentifedUsers, Source.Nick) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyAlreadyIDd, "%c", channel.Name))
    ElseIf HasFlag(channel.Name, Source.Nick, "+" + CHANSERV_COFOUNDER) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyAlreadyIDd, "%c", channel.Name))
    'Banned from the channel (via AKICK or +K flag)?
    ElseIf GetFirstAKick(channel.Name, Source) <> "" Or HasFlag(channel.Name, Source.Nick, "+" + CHANSERV_AUTOKICK) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyBanned, "%c", channel.Name))
    'Is the channel restricted, and the user not on the ACL (thus effectively +K'd)?
    ElseIf DB(channel.Name)("Restricted") And AllFlags(channel.Name, Source.Nick) = "" Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyRestricted, "%c", channel.Name))
    'Is the channel +A, +O, or +z, and the user is not?
    ElseIf (InStr(channel.Modes, "A") > 0 And InStr(Source.Modes, "A") = 0) Or (InStr(channel.Modes, "O") > 0 And InStr(Source.Modes, "o") = 0) Or (InStr(channel.Modes, "z") > 0 And InStr(Source.Modes, "z") = 0) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyRestricted, "%c", channel.Name))
    'Is the password correct?
    ElseIf Password <> DB(channel.Name)("Password") Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.ChanServIdentifyBadPass)
        Source.BadIdentifies = Source.BadIdentifies + 1
        If Source.BadIdentifies >= basMain.Config.BadPassLimit Then
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.ChanServIdentifyBadPassLimit)
            Source.KillUser Replies.KillReasonPasswordLimit, Service(SVSINDEX_CHANSERV).Nick
            Exit Sub 'Make absolutely sure we bail out.
        End If
    Else
        'All validations pass (or did I forget any?)... so mark him as identified.
        channel.IdentifedUsers.Add Source
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyOK, "%c", channel.Name))
        If channel.Members.Exists(Source) Then
            Call basFunctions.SendData(":" + Service(SVSINDEX_CHANSERV).Nick + " MODE " + channel.Name + " +ao " + Source.Nick + " " + Source.Nick)
            channel.SetChannelModes Service(SVSINDEX_CHANSERV).Nick, "+ao " + Source.Nick + " " + Source.Nick
        End If
    End If
End Sub

Public Sub Access(ByVal Source As User, ByVal channel As channel, ByVal Subcommand As String, Optional ByVal NickName As String = "", Optional ByVal Flags As String = "")

End Sub

Public Sub ManageMaskList(ByVal Source As User, ByVal channel As channel, ByVal List As String, ByVal Subcommand As String, Optional ByVal Entry As String = "", Optional ByVal Reason As String = "")

End Sub

Public Sub Invite(ByVal Source As User, ByVal channel As channel, ByVal Nick As User)

End Sub

Public Sub Unban(ByVal Source As User, ByVal channel As channel, ByVal User As User)

End Sub

Public Sub StatusChange(ByVal Source As User, ByVal channel As channel, ByVal What As String, ByVal Target As User)

End Sub

Public Sub StandardList(ByVal Source As User, ByVal channel As channel, ByVal What As String, ByVal Target As String)

End Sub

Public Sub BootUser(ByVal Source As User, ByVal channel As channel, ByVal Target As User, ByVal Message As String, Optional ByVal BanType As Integer = -1)

End Sub

Public Sub Topic(ByVal Source As User, ByVal channel As channel, ByVal NewTopic As String)

End Sub

Public Sub Mode(ByVal Source As User, ByVal channel As channel, ByVal ModeChange As String)

End Sub

Public Sub ChannelSetting(ByVal Source As User, ByVal channel As channel, ByVal Setting As String)

End Sub

Public Sub LockChange(ByVal Source As User, ByVal channel As channel, ByVal Locking As Boolean, ByVal SubLock As String, Optional ByVal Entry As String = "")

End Sub

Public Sub Drop(ByVal Source As User, ByVal channel As channel, Optional ByVal ConfirmationCode As String)

End Sub

Public Sub Forbid(ByVal Source As User, ByVal channel As channel, ByVal Reason As String)

End Sub

Public Sub Suspend(ByVal Source As User, ByVal channel As channel, ByVal Reason As String)

End Sub

Public Sub Unsuspend(ByVal Source As User, ByVal channel As channel)

End Sub

Private Sub Help(ByVal Sender As User, ByVal Cmd As String)
    Dim SenderNick As String
    SenderNick = Sender.Nick
    Dim s() As String
    s = Split(Cmd, " ")
    CommandHelp Sender, s, "chanserv", SVSINDEX_CHANSERV
End Sub

Private Sub Version(Sender As User)
    Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Sender.Nick, AppName & "-" & AppVersion & "[" & AppCompileInfo & "] - " & basMain.Service(SVSINDEX_CHANSERV).Nick & "[" & sNickServ.ModVersion & "]")
End Sub

'Callin subs for channel mode changes
Public Sub HandlePrefix(ByVal Source As String, ByVal Chan As channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As User)
    'We bounce this if:
    '- If it aint a service! :D
    '- strict_status and sender is not +V (for (de)voicing) +H (for (de)halfopping) +O (for (de)opping)
    '  +P (for (de)admining) or +N (for (de)ownering).
    '- For voicing, secure_voiceS and target isn't on ACL, or target is +q or +Q.
    '- For halfopping, secure_halfops and target isn't on ACL, or target is +D.
    '- For opping, admining, or ownering, secure_ops and target isn't on ACL, or target is +d.
    If IsServicesNick(Source) Then Exit Sub
    If Source = "" Or InStr(Source, ".") > 0 Then
        'SERVER VOICE / (HALF)OP
        If (Not DB(Chan.Name)("leave_ops")) And bSet Then
            Select Case Char
                Case "v" 'Do we really care about this?
                Case "h"
                    If Target.IdentifiedToNick <> "" Then
                        If HasFlag(Chan.Name, Target.IdentifiedToNick, "-" & CHANSERV_HALFOP & CHANSERV_HALFOPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                            'Not a halfop, so bounce it.
                            '(Techinically, we should allow an op to keep halfops, but oh well :P .)
                            Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-h", Target.Nick
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                            Exit Sub
                        End If
                    Else
                        'Not a halfop, so bounce it.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-h", Target.Nick
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                        Exit Sub
                    End If
                Case "o"
                    If Target.IdentifiedToNick <> "" Then
                        If HasFlag(Chan.Name, Target.IdentifiedToNick, "-" & CHANSERV_OP & CHANSERV_OPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                            'Not an op, so bounce it.
                            '(Techincally, we should allow admins and owners to keep it, but oh well :P .)
                            Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-o", Target.Nick
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                            Exit Sub
                        End If
                    Else
                        'Not an op, so bounce it.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-o", Target.Nick
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                        Exit Sub
                    End If
                Case "a"
                    If Target.IdentifiedToNick <> "" Then
                        If HasFlag(Chan.Name, Target.IdentifiedToNick, "-" & CHANSERV_PROTECT & CHANSERV_PROTECTOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                            'Not a protected user, so bounce it.
                            '(Techinically, we should allow an owner to keep admin, but oh well :P .)
                            Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-a", Target.Nick
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                            Exit Sub
                        End If
                    Else
                        'Not a protected user, so bounce it.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-a", Target.Nick
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                        Exit Sub
                    End If
                Case "q"
                    If Target.IdentifiedToNick <> "" Then
                        If HasFlag(Chan.Name, Target.IdentifiedToNick, "-" & CHANSERV_OWNER & CHANSERV_OWNEROP & CHANSERV_PERMFOUNDER) Then
                            'Not an owner, so bounce it.
                            Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-q", Target.Nick
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                            Exit Sub
                        End If
                    Else
                        'Not an owner, so bounce it.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-q", Target.Nick
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                        Exit Sub
                    End If
                'End Case
            End Select
        End If
    End If
    'Now for the normal checks.
    Dim uSender As User
    Set uSender = Users(Source)
    'If uSender Is Nothing Then Either Server Or Unknown User.
    If Not uSender Is Nothing Then
        If bSet Then
            Select Case Char
                Case "v"
                    'Bounce if:
                    'Target is +q / +Q
                    'secure_voice and user isn't on the ACL.
                    'strict_status and source doesn't have +V.
                    'So first thing is the sender's ACL check.
                    'EXCEPTION - USER VOICES SELF
                    If DB(Chan.Name)("strict_status") And Source = Target.Nick And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_VOICE & CHANSERV_VOICEOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-v", Target.Nick
                    ElseIf DB(Chan.Name)("strict_status") And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_VOICEOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-v", Target.Nick
                    ElseIf (DB(Chan.Name)("secure_voice") And AllFlags(Chan.Name, Target.IdentifiedToNick) = "") Or HasAnyFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_QUIET & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER, "+" & CHANSERV_SUPERQUIET & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-v", Target.Nick
                    End If
                Case "h"
                    'Bounce if:
                    'Target is +D
                    'secure_halfops and user isn't on the ACL.
                    'strict_status and source doesn't have +H.
                    If DB(Chan.Name)("strict_status") And Source = Target.Nick And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_HALFOP & CHANSERV_HALFOPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-h", Target.Nick
                    ElseIf DB(Chan.Name)("strict_status") And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_HALFOPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-h", Target.Nick
                    ElseIf (DB(Chan.Name)("secure_halfops") And AllFlags(Chan.Name, Target.IdentifiedToNick) = "") Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEHALFOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-h", Target.Nick
                    End If
                Case "o"
                    'Bounce if:
                    'Target is +d
                    'secure_ops and target isn't on the ACL.
                    'strict_status and source doesn't have +O.
                    If DB(Chan.Name)("strict_status") And Source = Target.Nick And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OP & CHANSERV_OPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-o", Target.Nick
                    ElseIf DB(Chan.Name)("strict_status") And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-o", Target.Nick
                    ElseIf (DB(Chan.Name)("secure_ops") And AllFlags(Chan.Name, Target.IdentifiedToNick) = "") Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-o", Target.Nick
                    End If
                Case "a"
                    'Bounce if:
                    'Target is +d
                    'secure_ops and target isn't on the ACL.
                    'strict_status and source doesn't have +P.
                    If DB(Chan.Name)("strict_status") And Source = Target.Nick And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_PROTECT & CHANSERV_PROTECTOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-a", Target.Nick
                    ElseIf DB(Chan.Name)("strict_status") And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_PROTECTOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-a", Target.Nick
                    ElseIf (DB(Chan.Name)("secure_ops") And AllFlags(Chan.Name, Target.IdentifiedToNick) = "") Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-a", Target.Nick
                    End If
                Case "q"
                    'Bounce if:
                    'Target is +d
                    'secure_ops and target isn't on the ACL.
                    'strict_status and source doesn't have +N.
                    If DB(Chan.Name)("strict_status") And Source = Target.Nick And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OWNER & CHANSERV_OWNEROP & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-q", Target.Nick
                    ElseIf DB(Chan.Name)("strict_status") And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OWNEROP & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-q", Target.Nick
                    ElseIf (DB(Chan.Name)("secure_ops") And AllFlags(Chan.Name, Target.IdentifiedToNick) = "") Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-q", Target.Nick
                    End If
                'End Case
            End Select
        Else
            'Unsetting. Rules are different here.
            Select Case Char
                Case "v"
                    'Bounce if:
                    'strict_status and source doesn't have +V.
                    'Target is of a higher level.
                    'If target == source (ie devoicing self) we don't care.
                    If Target.Nick <> Source And DB(Chan.Name)("strict_status") And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_VOICEOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+v", Target.Nick
                    ElseIf AccessLevel(Chan.Name, uSender.IdentifiedToNick) < AccessLevel(Chan.Name, Target.IdentifiedToNick) Then
                        'Just bounce it for now.
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+v", Target.Nick
                    End If
                Case "h"
                    'Bounce if:
                    'strict_status and source doesn't have +H.
                    'Target is of a higher level.
                    If Target.Nick <> Source And DB(Chan.Name)("strict_status") And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_HALFOPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+h", Target.Nick
                    ElseIf AccessLevel(Chan.Name, uSender.IdentifiedToNick) < AccessLevel(Chan.Name, Target.IdentifiedToNick) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+h", Target.Nick
                    End If
                Case "o"
                    'Bounce if:
                    'strict_status and source doesn't have +O.
                    'Target is of a higher level.
                    'Note: we can't pick service bot deops here. We'll have to use the MODE command
                    'callback for that.
                    If Target.Nick <> Source And DB(Chan.Name)("strict_status") And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+o", Target.Nick
                    ElseIf AccessLevel(Chan.Name, uSender.IdentifiedToNick) < AccessLevel(Chan.Name, Target.IdentifiedToNick) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+o", Target.Nick
                    End If
                Case "a"
                    'Bounce if:
                    'strict_status and source doesn't have +A.
                    'Target is of a higher level.
                    'Note: we can't pick service bot deops here. We'll have to use the MODE command
                    'callback for that.
                    If Target.Nick <> Source And DB(Chan.Name)("strict_status") And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_PROTECTOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+a", Target.Nick
                    ElseIf AccessLevel(Chan.Name, uSender.IdentifiedToNick) < AccessLevel(Chan.Name, Target.IdentifiedToNick) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+a", Target.Nick
                    End If
                Case "q"
                    'Bounce if:
                    'strict_status and source doesn't have +N.
                    'Target is of a higher level.
                    'Note: we can't pick service bot deops here. We'll have to use the MODE command
                    'callback for that.
                    If Target.Nick <> Source And DB(Chan.Name)("strict_status") And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OWNEROP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+q", Target.Nick
                    ElseIf AccessLevel(Chan.Name, uSender.IdentifiedToNick) < AccessLevel(Chan.Name, Target.IdentifiedToNick) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+q", Target.Nick
                    End If
                'End Case
            End Select
        End If
    Else
        'Unknown user or server mode. Do only target access checks here.
        If bSet Then
            Select Case Char
                Case "v"
                    If (DB(Chan.Name)("secure_voice") And AllFlags(Chan.Name, Target.IdentifiedToNick) = "") Or HasAnyFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_QUIET & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER, "+" & CHANSERV_SUPERQUIET & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-v", Target.Nick
                    End If
                Case "h"
                    If (DB(Chan.Name)("secure_halfops") And AllFlags(Chan.Name, Target.IdentifiedToNick) = "") Or HasAnyFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEHALFOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-h", Target.Nick
                    End If
                Case "o"
                    If (DB(Chan.Name)("secure_ops") And AllFlags(Chan.Name, Target.IdentifiedToNick) = "") Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-o", Target.Nick
                    End If
                Case "a"
                    If (DB(Chan.Name)("secure_ops") And AllFlags(Chan.Name, Target.IdentifiedToNick) = "") Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-a", Target.Nick
                    End If
                Case "q"
                    If (DB(Chan.Name)("secure_ops") And AllFlags(Chan.Name, Target.IdentifiedToNick) = "") Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        Chan.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-q", Target.Nick
                    End If
                'End Case
            End Select
        Else
            'Not sure what to do here.
        End If
    End If
End Sub

Public Sub HandleModeTypeA(ByVal Source As String, ByVal Chan As channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeB(ByVal Source As String, ByVal Chan As channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)
    DoMLOCK Chan, False
End Sub

Public Sub HandleModeTypeC(ByVal Source As String, ByVal Chan As channel, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)
    DoMLOCK Chan, False
End Sub

Public Sub HandleModeTypeD(ByVal Source As String, ByVal Chan As channel, ByVal bSet As Boolean, ByVal Char As String)
    DoMLOCK Chan, False
End Sub

Public Sub HandleCommand(ByVal Sender As String, ByVal Cmd As String, ByRef Args() As String)

End Sub

Public Sub HandleUserMode(ByVal User As User, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleTick(ByVal Interval As Single)
    Dim c As channel, sng As Single
    For Each c In Channels
        On Error GoTo InitTimer
        sng = c.Custom("LimitTimer")
        sng = sng - Interval
        If sng = 0 Then DoMLOCK c, True
        c.Custom.Remove ("LimitTimer")
        If sng > 0 Then c.Custom.Add sng, "LimitTimer"
ResumeLoop:
    Next c
    Exit Sub
InitTimer:
    c.Custom.Add 30!, "LimitTimer"
End Sub

Public Sub HandleEvent(ByVal Source As String, ByVal EventName As String, Parameters() As Variant)
    Select Case EventName
    
    End Select
End Sub

'Some general subs.
Public Sub InitChannel(ByVal channel As channel)
    Dim s As String
    s = DB(channel.Name)("bots")
    Dim vBots() As String
    vBots = Split(s, " ")
    'The first character will be the prefix, so...
    Dim v As Variant
    For Each v In vBots
        Call JoinBot(channel, Mid(v, 2))
    Next v
    DoMLOCK channel, True
    BotTopic channel, newcol("last_topic"), newcol("topic_set_by"), newcol("topic_set_on")
End Sub

'Enforces the MLOCK of the given channel.
Public Sub DoMLOCK(ByVal channel As channel, Optional ByVal UpdateFloatingLimit As Boolean = False)
    Dim mlock As String
    On Error Resume Next
    mlock = DB(channel.Name)("mlock")
    If Err.Number <> 0 Then 'Not registered, so the mlock is -r and nothing more.
        If InStr(1, channel.Modes, "r", vbBinaryCompare) Then
            channel.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-r"
        End If
        Exit Sub
    End If
    'Now parse the mlock.
    'The mlock is formatted as <binaryflags> [[<paramflags> <params>]]
    Dim m() As String
    m = Split(mlock, " ")
    Dim bSet As Boolean
    Dim sSet As String, sUnSet As String 'Modes we can send w/o a parameter.
    Dim idx As Long, ch As String * 1
    For idx = 1 To Len(m(0))
        ch = Mid(m(0), idx, 1)
        If ch = "+" Then
            bSet = True
        ElseIf ch = "-" Then
            bSet = False
        ElseIf bSet And ch = "l" And UpdateFloatingLimit Then
            BotMode channel, True, "+l " & CStr(channel.Members.Count + 8)
        ElseIf Not bSet And InStr(1, Split(basMain.ChannelModes2, ",", 2)(1), ch, vbBinaryCompare) Then
            '- and a Type B, C, or D mode.
            If ch = "f" And channel.FloodProtection <> "" Then
                BotMode channel, True, "-f " & channel.FloodProtection
            ElseIf ch = "k" And channel.ChannelKey <> "" Then
                BotMode channel, True, "-k " & channel.ChannelKey
            ElseIf ch = "L" And channel.OverflowChannel <> "" Then
                BotMode channel, True, "-L " & channel.OverflowChannel
            ElseIf ch = "l" And channel.OverflowLimit <> 0 Then
                sUnSet = sUnSet & "l"
            ElseIf InStr(1, channel.Modes, ch, vbBinaryCompare) Then
                sUnSet = sUnSet & ch
            End If
        ElseIf bSet And InStr(1, Split(basMain.ChannelModes2, ",")(3), ch, vbBinaryCompare) Then
            '+ and a Type D mode.
            If InStr(1, channel.Modes, ch, vbBinaryCompare) = 0 Then
                sSet = sSet & ch
            End If
        End If
    Next idx
    BotMode channel, True, "+" & sSet & "-" & sUnSet
    Dim Modes As String, idx2 As Long
    For idx = 1 To UBound(m)
        Modes = m(idx)
        For idx2 = 1 To Len(Modes)
            ch = Mid(Modes, idx2, 1)
            If ch = "+" Then
                'do nothing
            ElseIf ch = "-" Then
                'BAD BAD
            ElseIf InStr(1, Split(basMain.ChannelModes2, ",")(1) & Split(basMain.ChannelModes2, ",")(2), ch, vbBinaryCompare) Then
                'Eat a parameter then set the mode.
                idx = idx + 1
                Dim sParam As String
                sParam = m(idx)
                Select Case ch
                    Case "l":
                        If IsNumeric(sParam) Then
                            If channel.OverflowLimit <> CLng(sParam) Then
                                BotMode channel, True, "+l " & sParam
                            End If
                        End If
                    Case "k":
                        If channel.ChannelKey <> sParam Then
                            BotMode channel, True, "+k " & sParam
                        End If
                    Case "L":
                        If channel.OverflowChannel <> sParam Then
                            BotMode channel, True, "+L " & sParam
                        End If
                    Case "f":
                        If channel.FloodProtection <> sParam Then
                            BotMode channel, True, "+f " & sParam
                        End If
                    Case Else
                        'We can't optimize it down, so just send the dang thing already.
                        BotMode channel, True, FormatString("+{0} {1}", ch, sParam)
                    'End Case
                End Select
            End If
        Next idx2
    Next idx
End Sub

Public Sub JoinBot(ByVal channel As channel, ByVal Bot As String)
    Call basFunctions.SendData(":" + Bot & " JOIN " & channel.Name)
    Call basFunctions.SendData(":" + Bot & " MODE " & channel.Name & " +ao " & Bot & " " & Bot)
End Sub

Public Sub BotKick(ByVal channel As channel, ByVal Auto As Boolean, ByVal Target As User, ByVal Reason As String)
    Dim vBot As Variant
    vBot = IIf(Auto, DB(channel.Name)("bot_auto_kick"), DB(channel.Name)("bot_kick"))
    If IsNull(vBot) Then vBot = Service(SVSINDEX_CHANSERV).Nick
    channel.KickUser vBot, Target, Reason
End Sub

Public Sub BotMode(ByVal channel As channel, ByVal Auto As Boolean, ByVal Modes As String)
    Dim vBot As Variant
    vBot = IIf(Auto, DB(channel.Name)("bot_auto_mode"), DB(channel.Name)("bot_mode"))
    If IsNull(vBot) Then vBot = Service(SVSINDEX_CHANSERV).Nick
    channel.SendChannelModes vBot, Modes
End Sub

Public Sub BotTopic(ByVal channel As channel, ByVal Topic As String, ByVal SetBy As String, ByVal SetOn As Long)
    Dim vBot As Variant
    vBot = DB(channel.Name)("bot_topic")
    If IsNull(vBot) Then vBot = Service(SVSINDEX_CHANSERV).Nick
    channel.Topic = Topic
    channel.TopicSetBy = SetBy
    channel.TopicSetOn = SetOn
    Call basFunctions.SendData(FormatString(":{0} TOPIC {1} {2} {3} :{4}", vBot, channel.Name, SetBy, SetOn, Topic))
End Sub

Public Function HasFlag(ByVal channel As String, ByVal User As String, ByVal Flag As String) As Boolean
    'Checks the ACL if the user has specified flag(s).
    Dim sFlagsSet As String
    Dim sFlagsUnset As String
    Dim bSet As Boolean
    bSet = True
    Dim idx As Long, ch As String * 1
    For idx = 1 To Len(Flag)
        ch = Mid(Flag, idx, 1)
        Select Case ch
            Case "+": bSet = True
            Case "-": bSet = False
            Case Else: If bSet Then sFlagsSet = sFlagsSet + ch Else sFlagsUnset = sFlagsUnset + ch
        End Select
    Next idx
    Dim sResult As String
    sResult = AllFlags(channel, User)
    For idx = 1 To Len(sFlagsSet)
        If InStr(1, sResult, Mid(sFlagsSet, idx, 1), vbBinaryCompare) = 0 Then Exit Function
    Next idx
    For idx = 1 To Len(sFlagsUnset)
        If InStr(1, sResult, Mid(sFlagsUnset, idx, 1), vbBinaryCompare) > 0 Then Exit Function
    Next idx
    HasFlag = True
End Function

Public Function HasAnyFlag(ByVal channel As String, ByVal User As String, ParamArray Flags() As Variant) As Boolean
    Dim idx As Long
    For idx = LBound(Flags) To UBound(Flags)
        If Not IsMissing(Flags(idx)) Then
            If HasFlag(channel, User, Flags(idx)) Then
                HasAnyFlag = True
                Exit Function
            End If
        End If
    Next idx
End Function

Public Sub SetFlag(ByVal channel As String, ByVal User As String, ByVal Flag As String)
    Dim bSet As Boolean
    Dim idx As Long, ch As String * 1
    Dim sResult As String
    sResult = AllFlags(channel, User)
    For idx = 1 To Len(Flag)
        ch = Mid(Flag, idx, 1)
        Select Case ch
            Case "+": bSet = True
            Case "-": bSet = False
            Case Else: If bSet Then sResult = sResult + ch Else sResult = Replace(sResult, ch, "")
        End Select
    Next idx
    AllFlags(channel, User) = sResult
End Sub

Public Property Get AllFlags(ByVal channel As String, ByVal User As String) As String
    If channel = "" Or User = "" Then Exit Property
    Dim sACL As String
    sACL = DB(channel)("AccessList")
    Dim vACL As Variant
    vACL = Split(sACL, vbTab)
    Dim idx As Long
    For idx = 0 To UBound(vACL)
        If Split(vACL(idx), " ")(0) = User Then
            AllFlags = Split(vACL(idx), " ")(1)
            Exit Property
        End If
    Next idx
    'Not found so return null.
    AllFlags = ""
End Property

Public Property Let AllFlags(ByVal channel As String, ByVal User As String, ByVal Flags As String)
    If channel = "" Or User = "" Then Err.Raise 9, , "No such nick/channel"
    Dim sACL As String, vACL As Variant, bFound As Boolean
    sACL = DB(channel)("AccessList")
    vACL = Split(sACL, vbTab)
    Dim idx As Long
    For idx = 0 To UBound(vACL)
        If Split(vACL(idx), " ")(0) = User Then
            If Flags = "" Then
                'Mark it for removal.
                vACL(idx) = ""
            Else
                vACL(idx) = Join(Array(Split(vACL(idx), " ")(0), Flags), " ")
            End If
            bFound = True
            Exit For
        End If
    Next idx
    If Not bFound Then
        'We have to add it.
        ReDim Preserve vACL(UBound(vACL) + 1)
        vACL(UBound(vACL)) = User & " " & Flags
    End If
    sACL = Join(vACL, vbTab)
    While InStr(sACL, vbTab & vbTab): sACL = Replace(sACL, vbTab & vbTab, vbTab): Wend
    'Wish I could retain the order here but...
    SetItem(DB(channel), "AccessList") = sACL
End Property

Public Sub DelAllFlags(ByVal channel As String, ByVal User As String)
    AllFlags(channel, User) = ""
End Sub

Public Function GetFirstAKick(ByVal channel As String, ByVal User As User) As String
    Dim sAK As String, vAK As Variant
    sAK = DB(channel)("AKicks")
    vAK = Split(sAK, vbCrLf)
    Dim idx As Long, vEntry As Variant
    For idx = 0 To UBound(vAK)
        vEntry = Split(vAK(idx), " ", 3)
        If NUHMaskIsMatch(User, vEntry(0)) Then
            GetFirstAKick = vEntry(0)
            Exit Function
        End If
    Next idx
    GetFirstAKick = ""
End Function

Public Property Get AKickReason(ByVal channel As String, ByVal AKickMask As String) As String
    Dim sAK As String, vAK As Variant
    sAK = DB(channel)("AKicks")
    vAK = Split(sAK, vbCrLf)
    Dim idx As Long, vEntry As Variant
    For idx = 0 To UBound(vAK)
        vEntry = Split(vAK(idx), " ", 3)
        If vEntry(0) = AKickMask Then
            AKickReason = vEntry(2)
            Exit Function
        End If
    Next idx
    AKickReason = ""
End Property

Public Property Get AKickExpiry(ByVal channel As String, ByVal AKickMask As String) As Double
    Dim sAK As String, vAK As Variant
    sAK = DB(channel)("AKicks")
    vAK = Split(sAK, vbCrLf)
    Dim idx As Long, vEntry As Variant
    For idx = 0 To UBound(vAK)
        vEntry = Split(vAK(idx), " ", 3)
        If vEntry(0) = AKickMask Then
            AKickExpiry = CDbl(vEntry(1))
            Exit Property
        End If
    Next idx
    AKickExpiry = -1
End Property

Public Property Let AKickExpiry(ByVal channel As String, ByVal AKickMask As String, ByVal NewExpiry As Double)
    Dim sAK As String, vAK As Variant
    sAK = DB(channel)("AKicks")
    vAK = Split(sAK, vbCrLf)
    Dim idx As Long, vEntry As Variant
    For idx = 0 To UBound(vAK)
        vEntry = Split(vAK(idx), " ", 3)
        If AKickMask = vEntry(0) Then
            vEntry(1) = CStr(NewExpiry)
            vAK(idx) = Join(vEntry, " ")
            sAK = Join(vAK, vbCrLf)
            DB(channel)("AKicks") = sAK
        End If
    Next idx
End Property

Public Sub AddAKick(ByVal channel As String, ByVal AKickMask As String, ByVal Expiry As Double, ByVal Reason As String)
    If AKickExpiry(channel, AKickMask) >= 0 Then Exit Sub
    Dim sResult As String
    sResult = DB(channel)("AKicks")
    sResult = sResult & vbCrLf & AKickMask & " " & CStr(Expiry) & " " & Reason
    DB(channel)("AKick") = sResult
End Sub

Public Sub DelAKick(ByVal channel As String, ByVal AKickMask As String)
    Dim sResult As String, vSplit As Variant
    sResult = DB(channel)("AKicks")
    vSplit = Split(sResult, vbCrLf)
    Dim idx As Long
    For idx = 0 To UBound(vSplit)
        If Split(vSplit(idx), " ", 3)(0) = AKickMask Then
            vSplit(idx) = ""
        End If
    Next idx
    'Now rejoin them
    sResult = Join(vSplit, vbCrLf)
    'Removed items will be vbCrLf vbCrLf
    While InStr(sResult, vbCrLf + vbCrLf): sResult = Replace(sResult, vbCrLf + vbCrLf, vbCrLf): Wend
End Sub

Public Function GetFirstExempt(ByVal channel As String, ByVal User As User) As String
    Dim sExempt As String, vExempt As Variant
    sExempt = DB(channel)("Exempts")
    vExempt = Split(sExempt, vbCrLf)
    Dim idx As Long, vEntry As Variant
    For idx = 0 To UBound(vExempt)
        vEntry = Split(vExempt(idx), " ", 3)
        If NUHMaskIsMatch(User, vEntry(0)) Then
            GetFirstExempt = vEntry(0)
            Exit Function
        End If
    Next idx
    GetFirstExempt = ""
End Function

Public Property Get ExemptExpiry(ByVal channel As String, ByVal ExemptMask As String) As Double
    Dim sExempt As String, vExempt As Variant
    sExempt = DB(channel)("Exempts")
    vExempt = Split(sExempt, vbCrLf)
    Dim idx As Long, vEntry As Variant
    For idx = 0 To UBound(vExempt)
        vEntry = Split(vExempt(idx), " ", 3)
        If vEntry(0) = ExemptMask Then
            ExemptExpiry = CDbl(vEntry(1))
            Exit Property
        End If
    Next idx
    ExemptExpiry = -1
End Property

Public Property Let ExemptExpiry(ByVal channel As String, ByVal ExemptMask As String, ByVal NewExpiry As Double)
    Dim sExempt As String, vExempt As Variant
    sExempt = DB(channel)("Exempts")
    vExempt = Split(sExempt, vbCrLf)
    Dim idx As Long, vEntry As Variant
    For idx = 0 To UBound(vExempt)
        vEntry = Split(vExempt(idx), " ", 3)
        If ExemptMask = vEntry(0) Then
            vEntry(1) = CStr(NewExpiry)
            vExempt(idx) = Join(vEntry, " ")
            sExempt = Join(vExempt, vbCrLf)
            DB(channel)("Exempts") = sExempt
        End If
    Next idx
End Property

Public Sub AddExempt(ByVal channel As String, ByVal ExemptMask As String, ByVal Expiry As Double)
    If ExemptExpiry(channel, ExemptMask) >= 0 Then Exit Sub
    Dim sResult As String
    sResult = DB(channel)("Exempts")
    sResult = sResult & vbCrLf & ExemptMask & " " & CStr(Expiry)
    DB(channel)("Exempt") = sResult
End Sub

Public Sub DelExempt(ByVal channel As String, ByVal ExemptMask As String)
    Dim sResult As String, vSplit As Variant
    sResult = DB(channel)("Exempts")
    vSplit = Split(sResult, vbCrLf)
    Dim idx As Long
    For idx = 0 To UBound(vSplit)
        If Split(vSplit(idx), " ", 3)(0) = ExemptMask Then
            vSplit(idx) = ""
        End If
    Next idx
    'Now rejoin them
    sResult = Join(vSplit, vbCrLf)
    'Removed items will be vbCrLf vbCrLf
    While InStr(sResult, vbCrLf + vbCrLf): sResult = Replace(sResult, vbCrLf + vbCrLf, vbCrLf): Wend
End Sub

Public Function GetFirstInvite(ByVal channel As String, ByVal User As User) As String
    Dim sInvite As String, vInvite As Variant
    sInvite = DB(channel)("Invites")
    vInvite = Split(sInvite, vbCrLf)
    Dim idx As Long, vEntry As Variant
    For idx = 0 To UBound(vInvite)
        vEntry = Split(vInvite(idx), " ", 3)
        If NUHMaskIsMatch(User, vEntry(0)) Then
            GetFirstInvite = vEntry(0)
            Exit Function
        End If
    Next idx
    GetFirstInvite = ""
End Function

Public Property Get InviteExpiry(ByVal channel As String, ByVal InviteMask As String) As Double
    Dim sInvite As String, vInvite As Variant
    sInvite = DB(channel)("Invites")
    vInvite = Split(sInvite, vbCrLf)
    Dim idx As Long, vEntry As Variant
    For idx = 0 To UBound(vInvite)
        vEntry = Split(vInvite(idx), " ", 3)
        If vEntry(0) = InviteMask Then
            InviteExpiry = CDbl(vEntry(1))
            Exit Property
        End If
    Next idx
    InviteExpiry = -1
End Property

Public Property Let InviteExpiry(ByVal channel As String, ByVal InviteMask As String, ByVal NewExpiry As Double)
    Dim sInvite As String, vInvite As Variant
    sInvite = DB(channel)("Invites")
    vInvite = Split(sInvite, vbCrLf)
    Dim idx As Long, vEntry As Variant
    For idx = 0 To UBound(vInvite)
        vEntry = Split(vInvite(idx), " ", 3)
        If InviteMask = vEntry(0) Then
            vEntry(1) = CStr(NewExpiry)
            vInvite(idx) = Join(vEntry, " ")
            sInvite = Join(vInvite, vbCrLf)
            DB(channel)("Invites") = sInvite
        End If
    Next idx
End Property

Public Sub AddInvite(ByVal channel As String, ByVal InviteMask As String, ByVal Expiry As Double)
    If InviteExpiry(channel, InviteMask) >= 0 Then Exit Sub
    Dim sResult As String
    sResult = DB(channel)("Invites")
    sResult = sResult & vbCrLf & InviteMask & " " & CStr(Expiry)
    DB(channel)("Invite") = sResult
End Sub

Public Sub DelInvite(ByVal channel As String, ByVal InviteMask As String)
    Dim sResult As String, vSplit As Variant
    sResult = DB(channel)("Invites")
    vSplit = Split(sResult, vbCrLf)
    Dim idx As Long
    For idx = 0 To UBound(vSplit)
        If Split(vSplit(idx), " ", 3)(0) = InviteMask Then
            vSplit(idx) = ""
        End If
    Next idx
    'Now rejoin them
    sResult = Join(vSplit, vbCrLf)
    'Removed items will be vbCrLf vbCrLf
    While InStr(sResult, vbCrLf + vbCrLf): sResult = Replace(sResult, vbCrLf + vbCrLf, vbCrLf): Wend
End Sub

Public Function AccessLevel(ByVal channel As String, ByVal User As String) As Integer
    'Returns a number indicating the "level" of a user:
    'Voice - 1
    'VoiceOp - 2
    'HalfOp - 3
    'HalfOpOp - 4
    'Op - 5
    'OpOp - 6
    'Protected - 7
    'ProtectedOp - 8
    'Owner - 9
    'OwnerOp - 10
    'CoFounder - 11
    'PermFounder - 12
    If HasFlag(channel, User, CHANSERV_PERMFOUNDER) Then
        AccessLevel = 12
    ElseIf HasFlag(channel, User, CHANSERV_COFOUNDER) Then
        AccessLevel = 11
    ElseIf HasFlag(channel, User, CHANSERV_OWNEROP) Then
        AccessLevel = 10
    ElseIf HasFlag(channel, User, CHANSERV_OWNER) Then
        AccessLevel = 9
    ElseIf HasFlag(channel, User, CHANSERV_PROTECTOP) Then
        AccessLevel = 8
    ElseIf HasFlag(channel, User, CHANSERV_PROTECT) Then
        AccessLevel = 7
    ElseIf HasFlag(channel, User, CHANSERV_OPOP) Then
        AccessLevel = 6
    ElseIf HasFlag(channel, User, CHANSERV_OP) Then
        AccessLevel = 5
    ElseIf HasFlag(channel, User, CHANSERV_HALFOPOP) Then
        AccessLevel = 4
    ElseIf HasFlag(channel, User, CHANSERV_HALFOP) Then
        AccessLevel = 3
    ElseIf HasFlag(channel, User, CHANSERV_VOICEOP) Then
        AccessLevel = 2
    ElseIf HasFlag(channel, User, CHANSERV_VOICE) Then
        AccessLevel = 1
    End If
End Function
