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
    
Public Enum LOCKLEVEL
    LOCK_NONE = 0
    LOCK_LOCK = 1
    LOCK_CFOUNDER = 2
    LOCK_FOUNDER = 3
End Enum
    
Public Type ACE
    Nick As String
    Flags As String
    Lock As LOCKLEVEL
End Type

Public Type AutoKick
    Mask As String
    Expiry As Long
    Reason As String
    Lock As LOCKLEVEL
End Type

Public Type Exempt
    Mask As String
    Expiry As Long
    Lock As LOCKLEVEL
End Type

Public Type ChanServDataRecord
    Name As String
    Password As String
    Description As String
    Suspended As Boolean
    Successor As String
    AccessList() As ACE
    AKicks() As AutoKick
    Exempts() As Exempt
    Invites() As Exempt
    SecureOps As Boolean
    SecureHalfOps As Boolean
    SecureVoices As Boolean
    Restricted As Boolean
    Secure As Boolean
    LeaveOps As Boolean
    TopicLock As Boolean
    StrictStatus As Boolean
    StrictList As Boolean
    LearnBans As Boolean
    ForgetBans As Boolean
    Give As Boolean
    StrictMode As Boolean
    MLock As String
    LastTopic As String
    TopicSetBy As String
    TopicSetOn As Long
    TimeRegistered As Long
    LastJoin As Long
    Bots() As String
    BotKick As String
    BotMode As String
    BotTopic As String
    BotGreet As String
    BotAutoKick As String
    BotAutoMode As String
    NoKickOps As Boolean
    NoKickVoice As Boolean
    NoBot As Boolean
    KickBold As Integer
    KickBadWords As Integer
    KickCaps As Integer
    KickColor As Integer
    KickFlood As Integer
    KickRepeat As Integer
    KickReverse As Integer
    KickUnderlines As Integer
    KickCapsMinimum As Integer
    KickCapsTrigger As Integer
    KickFloodLines As Integer
    KickFloodDuration As Integer
    KickRepeatCount As Integer
    KickBWList() As String
End Type

Public DB() As ChanServDataRecord

'These two are important!!!
Public Sub LoadData(ByVal conn As Connection)
    Dim mDB As Collection
    Set mDB = ReadTableIntoCollection(conn, "ChanServ")
    Dim idx As Long, subcol As Collection
    If mDB.Count <= 0 Then
        Erase DB()
        Exit Sub
    End If
    ReDim DB(0 To mDB.Count - 1)
    For idx = 1 To mDB.Count
        Set subcol = mDB(idx)
        With DB(idx - 1)
            .Name = subcol("name")
            .Password = subcol("password")
            .Description = subcol("description")
            .Suspended = subcol("suspended")
            .Successor = subcol("successor")
            Dim v As Variant, v2 As Variant, idx2 As Long
            If Len(subcol("access_list")) > 0 Then
                v = Split(subcol("access_list"), vbTab)
                ReDim .AccessList(0 To UBound(v))
                For idx2 = 0 To UBound(v)
                    With .AccessList(idx2)
                        v2 = Split(v(idx2), " ")
                        If InStr("!#@", Left(v2(0), 1)) > 0 Then
                            .Lock = Choose(InStr("!#@", Left(v2(0), 1)), LOCKLEVEL.LOCK_LOCK, LOCKLEVEL.LOCK_CFOUNDER, LOCKLEVEL.LOCK_FOUNDER)
                            .Nick = Mid(v2(0), 2)
                        Else
                            .Lock = LOCK_NONE
                            .Nick = v2(0)
                        End If
                        .Flags = v2(1)
                    End With
                Next idx2
            Else
                Erase .AccessList
            End If
            If Len(subcol("akicks")) > 0 Then
                v = Split(subcol("akicks"), vbCrLf)
                ReDim .AKicks(0 To UBound(v))
                For idx2 = 0 To UBound(v)
                    With .AKicks(idx2)
                        v2 = Split(v(idx), " ", 3)
                        If InStr("!#@", Left(v2(0), 1)) > 0 Then
                            .Lock = Choose(InStr("!#@", Left(v2(0), 1)), LOCKLEVEL.LOCK_LOCK, LOCKLEVEL.LOCK_CFOUNDER, LOCKLEVEL.LOCK_FOUNDER)
                            .Mask = Mid(v2(0), 2)
                        Else
                            .Lock = LOCK_NONE
                            .Mask = v2(0)
                        End If
                        .Expiry = v2(1)
                        .Reason = v2(2)
                    End With
                Next idx2
            Else
                Erase .AKicks
            End If
            If Len(subcol("exempts")) > 0 Then
                v = Split(subcol("exempts"), vbCrLf)
                ReDim .Exempts(0 To UBound(v))
                For idx2 = 0 To UBound(v)
                    With .Exempts(idx2)
                        v2 = Split(v(idx), " ", 2)
                        If InStr("!#@", Left(v2(0), 1)) > 0 Then
                            .Lock = Choose(InStr("!#@", Left(v2(0), 1)), LOCKLEVEL.LOCK_LOCK, LOCKLEVEL.LOCK_CFOUNDER, LOCKLEVEL.LOCK_FOUNDER)
                            .Mask = Mid(v2(0), 2)
                        Else
                            .Lock = LOCK_NONE
                            .Mask = v2(0)
                        End If
                        .Expiry = v2(1)
                    End With
                Next idx2
            Else
                Erase .Exempts
            End If
            If Len(subcol("invites")) > 0 Then
                v = Split(subcol("invites"), vbCrLf)
                ReDim .Invites(0 To UBound(v))
                For idx2 = 0 To UBound(v)
                    With .Invites(idx2)
                        v2 = Split(v(idx), " ", 2)
                        If InStr("!#@", Left(v2(0), 1)) > 0 Then
                            .Lock = Choose(InStr("!#@", Left(v2(0), 1)), LOCKLEVEL.LOCK_LOCK, LOCKLEVEL.LOCK_CFOUNDER, LOCKLEVEL.LOCK_FOUNDER)
                            .Mask = Mid(v2(0), 2)
                        Else
                            .Lock = LOCK_NONE
                            .Mask = v2(0)
                        End If
                        .Expiry = v2(1)
                    End With
                Next idx2
            Else
                Erase .Invites
            End If
            .SecureOps = subcol("secure_ops")
            .SecureHalfOps = subcol("secure_halfops")
            .SecureVoices = subcol("secure_voices")
            .Restricted = subcol("restricted")
            .Secure = subcol("secure")
            .LeaveOps = subcol("leave_ops")
            .TopicLock = subcol("topic_lock")
            .StrictStatus = subcol("strict_status")
            .StrictList = subcol("strict_list")
            .LearnBans = subcol("learn_bans")
            .ForgetBans = subcol("forget_bans")
            .Give = subcol("give")
            .StrictMode = subcol("strict_mode")
            .MLock = subcol("mlock")
            .LastTopic = subcol("last_topic")
            .TopicSetBy = subcol("topic_set_by")
            .TopicSetOn = subcol("topic_set_on")
            .TimeRegistered = subcol("time_registered")
            .LastJoin = subcol("last_join")
            .Bots = Split(subcol("bots"), " ")
            .BotKick = subcol("bot_kick")
            .BotMode = subcol("bot_mode")
            .BotTopic = subcol("bot_topic")
            .BotGreet = subcol("bot_greet")
            .BotAutoKick = subcol("bot_auto_kick")
            .BotAutoMode = subcol("bot_auto_mode")
            .NoKickOps = subcol("no_kick_ops")
            .NoKickVoice = subcol("no_kick_voice")
            .NoBot = subcol("no_bot")
            .KickBold = subcol("kick_bold")
            .KickBadWords = subcol("kick_bad_words")
            .KickCaps = subcol("kick_caps")
            .KickColor = subcol("kick_color")
            .KickFlood = subcol("kick_flood")
            .KickRepeat = subcol("kick_repeat")
            .KickReverse = subcol("kick_reverse")
            .KickUnderlines = subcol("kick_underlines")
            .KickCapsMinimum = subcol("kick_caps_minimum")
            .KickCapsTrigger = subcol("kick_caps_trigger")
            .KickFloodLines = subcol("kick_flood_lines")
            .KickFloodDuration = subcol("kick_flood_duration")
            .KickRepeatCount = subcol("kick_repeat_count")
            .KickBWList() = Split(subcol("kick_bw_list"), vbTab)
        End With
    Next idx
End Sub

Public Sub SaveData(ByVal conn As Connection)
    'Great. Now we're writing to the database. This aint as easy :| .
    Dim rs As Recordset
    Set rs = GetTable(conn, "ChanServ")
    'Prepare the fields array in advance.
    Dim Fields(0 To 51) As String
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
    Dim vals(0 To 51) As Variant, v As Variant
    On Local Error Resume Next
    vals(0) = UBound(DB)
    If Err = 9 Then Exit Sub
    On Error GoTo 0
    With rs
        Dim idx As Long, idx2 As Long
        For idx = 0 To UBound(DB)
            vals(0) = DB(idx).Name
            vals(1) = DB(idx).Password
            vals(2) = DB(idx).Description
            vals(3) = DB(idx).Suspended
            vals(4) = DB(idx).Successor
            ReDim v(0 To UBound(DB(idx).AccessList))
            For idx2 = 0 To UBound(DB(idx).AccessList)
                v(idx2) = IIf(DB(idx).AccessList(idx2).Lock <> 0, Choose(DB(idx).AccessList(idx2).Lock, "!", "#", "@"), "") + DB(idx).AccessList(idx2).Nick & " " & DB(idx).AccessList(idx2).Flags
            Next idx2
            On Error GoTo PooNoAKicks
            ReDim v(0 To UBound(DB(idx).AKicks))
            For idx2 = 0 To UBound(DB(idx).AKicks)
                v(idx2) = IIf(DB(idx).AKicks(idx2).Lock <> 0, Choose(DB(idx).AKicks(idx2).Lock, "!", "#", "@"), "") + DB(idx).AKicks(idx2).Mask & " " & CStr(DB(idx).AKicks(idx2).Expiry) & " " & DB(idx).AKicks(idx2).Reason
            Next idx2
PooNoAKicks:
            If Err Then
                vals(6) = ""
            Else
                vals(6) = Join(v, vbTab)
            End If
            On Error GoTo PooNoExempts
            ReDim v(0 To UBound(DB(idx).Exempts))
            For idx2 = 0 To UBound(DB(idx).Exempts)
                v(idx2) = IIf(DB(idx).Exempts(idx2).Lock <> 0, Choose(DB(idx).Exempts(idx2).Lock, "!", "#", "@"), "") + DB(idx).Exempts(idx2).Mask & " " & CStr(DB(idx).Exempts(idx2).Expiry)
            Next idx2
PooNoExempts:
            If Err Then
                vals(7) = ""
            Else
                vals(7) = Join(v, vbTab)
            End If
            On Error GoTo PooNoInvites
            ReDim v(0 To UBound(DB(idx).Invites))
            For idx2 = 0 To UBound(DB(idx).Invites)
                v(idx2) = IIf(DB(idx).Invites(idx2).Lock <> 0, Choose(DB(idx).Invites(idx2).Lock, "!", "#", "@"), "") + DB(idx).Invites(idx2).Mask & " " & CStr(DB(idx).Invites(idx2).Expiry)
            Next idx2
PooNoInvites:
            If Err Then
                vals(8) = ""
            Else
                vals(8) = Join(v, vbTab)
            End If
            vals(9) = DB(idx).SecureOps
            vals(10) = DB(idx).SecureHalfOps
            vals(11) = DB(idx).SecureVoices
            vals(12) = DB(idx).Restricted
            vals(13) = DB(idx).Secure
            vals(14) = DB(idx).LeaveOps
            vals(15) = DB(idx).TopicLock
            vals(16) = DB(idx).StrictStatus
            vals(17) = DB(idx).StrictList
            vals(18) = DB(idx).LearnBans
            vals(19) = DB(idx).ForgetBans
            vals(20) = DB(idx).Give
            vals(21) = DB(idx).StrictMode
            vals(22) = DB(idx).MLock
            vals(23) = DB(idx).LastTopic
            vals(24) = DB(idx).TopicSetBy
            vals(25) = DB(idx).TopicSetOn
            vals(26) = DB(idx).TimeRegistered
            vals(27) = DB(idx).LastJoin
            vals(28) = Join(DB(idx).Bots, " ")
            vals(29) = DB(idx).BotKick
            vals(30) = DB(idx).BotMode
            vals(31) = DB(idx).BotTopic
            vals(32) = DB(idx).BotGreet
            vals(33) = DB(idx).BotAutoKick
            vals(34) = DB(idx).BotAutoMode
            vals(35) = DB(idx).NoKickOps
            vals(36) = DB(idx).NoKickVoice
            vals(37) = DB(idx).NoBot
            vals(38) = DB(idx).KickBold
            vals(39) = DB(idx).KickBadWords
            vals(40) = DB(idx).KickCaps
            vals(41) = DB(idx).KickColor
            vals(42) = DB(idx).KickFlood
            vals(43) = DB(idx).KickRepeat
            vals(44) = DB(idx).KickReverse
            vals(45) = DB(idx).KickUnderlines
            vals(46) = DB(idx).KickCapsMinimum
            vals(47) = DB(idx).KickCapsTrigger
            vals(48) = DB(idx).KickFloodLines
            vals(49) = DB(idx).KickFloodDuration
            vals(50) = DB(idx).KickRepeatCount
            vals(51) = Join(DB(idx).KickBWList, vbTab)
            .MoveFirst
            .Find "Name=" & DB(idx).Name
            If .BOF Or .EOF Then
                'Channel was registered since last update, so we need to create it.
                .AddNew Fields, vals
                .Update
            Else
                'Channel was previously registered, in which case we are pointing to a valid record.
                .Update Fields, vals
            End If
        Next idx
        'Now we need to look for channels in the database that we don't have in the collection - these
        'were dropped between updates, so we need to remove them from the DB or they get mysteriously
        'reregistered :) .
        .MoveFirst
        While Not .EOF
            'Now see if the current record is in our memory cache.
            If DBIndexOf(.Fields("name")) = -1 Then
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
                            If IsNumeric(Parameters(4)) Then
                                ManageMaskList Sender, Channels(Parameters(1)), Parameters(0), Parameters(2), Parameters(3), Parameters(4), Split(Cmd, " ", 6)(5)
                            Else
                                ManageMaskList Sender, Channels(Parameters(1)), Parameters(0), Parameters(2), Parameters(3), 0, Split(Cmd, " ", 5)(4)
                            End If
                        End If
                    Case "VIEW", "LIST", "ENFORCE"
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
        Case "CLEAR"
            If UBound(Parameters) < 2 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replies.InsufficientParameters)
            ElseIf Not Channels.Exists(Parameters(1)) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, SenderNick, Replace(Replies.ChanServChanEmpty, "%c", Parameters(1)))
                Call basFunctions.SendNumeric(SenderNick, 403, Parameters(1) & " :No such channel")
            Else
                Clear Sender, Channels(Parameters(1)), Parameters(2)
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

Public Sub Register(ByVal Source As User, ByVal Channel As Channel, ByVal Password As String, ByVal Description As String)
    'Now, first thing is, can we register this channel?
    'Conditions for registration:
    '- Channel isn't #
    '- Channel isn't "do not register"
    '- Channel isn't forbidden or suspended.
    '- Channel isn't an official channel listed in the configuration (Help, Operations, Debug).
    If Channel.Name = "#" Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServCantReg, "%s", "Null channel cannot be registered."), "%c", Channel.Name))
    ElseIf DBIndexOf(Channel.Name) >= 0 Then
        'It's already registered.
        If DB(DBIndexOf(Channel.Name)).Suspended And DB(DBIndexOf(Channel.Name)).Password = "" Then
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServCantReg, "%s", "Channel is forbidden"), "%c", Channel.Name))
        Else
            Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServAlreadyRegd, "%c", Channel.Name))
        End If
    'TODO: Add Help/Operations/Debug channel checks?
    ElseIf Not Channel.Members.Exists(Source.Nick) Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServRegNeedOps, "%c", Channel.Name))
        Call basFunctions.SendNumeric(Source.Nick, 482, Channel.Name & " :You're not channel operator.")
    ElseIf InStr(Channel.Members(Source.Nick).Modes, "o") = 0 And InStr(Channel.Members(Source.Nick).Modes, "a") = 0 And InStr(Channel.Members(Source.Nick).Modes, "q") = 0 Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServRegNeedOps, "%c", Channel.Name))
        Call basFunctions.SendNumeric(Source.Nick, 482, Channel.Name & " :You're not channel operator.")
    ElseIf Not Source.IdentifiedToNick = "" Then
        Call basFunctions.SendMessage(basMain.Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.ChanServYouArentRegistered)
    Else
        'Otherwise, we're okay to register.
        Dim nTime As Double
        nTime = basUnixTime.GetTime()
        ReDim Preserve DB(UBound(DB) + 1)
        With DB(UBound(DB))
            .Name = Channel.Name
            .Password = Password
            .Description = Description
            ReDim .AccessList(0)
            .AccessList(0).Lock = LOCK_FOUNDER
            .AccessList(1).Nick = Source.IdentifiedToNick
            .AccessList(2).Flags = "F"
            ReDim .Bots(0)
            .Bots(0) = "!" + Service(SVSINDEX_CHANSERV).Nick
            Erase .AKicks
            Erase .Exempts
            Erase .Invites
            .BotAutoKick = ""
            .BotAutoMode = ""
            .BotGreet = ""
            .BotKick = ""
            .BotMode = ""
            .BotTopic = ""
            .ForgetBans = False
            .Give = False
            .KickBadWords = -1
            .KickBold = -1
            .KickBWList = Array()
            .KickCaps = -1
            .KickCapsMinimum = 10
            .KickCapsTrigger = 25
            .KickColor = -1
            .KickFlood = -1
            .KickFloodDuration = 10
            .KickFloodLines = 5
            .KickRepeat = -1
            .KickRepeatCount = 3
            .KickReverse = -1
            .KickUnderlines = -1
            .LastJoin = nTime
            .LearnBans = False
            .LeaveOps = False
            .MLock = "+nt"
            .NoBot = False
            .NoKickOps = False
            .NoKickVoice = False
            .Restricted = False
            .Secure = False
            .SecureHalfOps = False
            .SecureVoices = False
            .StrictList = False
            .StrictMode = False
            .StrictStatus = False
            .Successor = ""
            .Suspended = False
            .TimeRegistered = nTime
            .TopicLock = False
            If Channel.Topic <> "" Then
                .LastTopic = Channel.Topic
                .TopicSetBy = Channel.TopicSetBy
                .TopicSetOn = Channel.TopicSetOn
            Else
                .LastJoin = "- This channel is now registered."
                .TopicSetBy = Service(SVSINDEX_CHANSERV).Nick
                .TopicSetOn = nTime
            End If
        End With
        'Now do what we need to do :).
        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, Channel.Name, "This channel is now operated by " + Service(SVSINDEX_CHANSERV).Nick + ".")
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServREGISTEROK, "%c", Channel.Name))
        InitChannel Channel
    End If
End Sub

Public Sub Identify(ByVal Source As User, ByVal Channel As Channel, ByVal Password As String)
    If Not IsChanRegistered(Channel.Name) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
    'Already identified, or already has cofounder access?
    ElseIf CollectionContains(Channel.IdentifedUsers, Source.Nick) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyAlreadyIDd, "%c", Channel.Name))
    ElseIf HasFlag(Channel.Name, Source.Nick, "+" + CHANSERV_COFOUNDER) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyAlreadyIDd, "%c", Channel.Name))
    'Banned from the channel (via AKICK or +K flag)?
    ElseIf (GetFirstAKick(Channel.Name, Source) >= 0 And (GetFirstExempt(Channel.Name, Source) < 0 And Not HasAnyFlag(Channel.Name, Source.Nick, CHANSERV_EXEMPT, CHANSERV_EXEMPTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER))) Or HasFlag(Channel.Name, Source.Nick, "+" + CHANSERV_AUTOKICK) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyBanned, "%c", Channel.Name))
        Call basFunctions.SendNumeric(Source.Nick, 474, Channel.Name + " :Cannot join channel (+b)")
        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Replace(Replace(Replace(Replies.ChanServIdentifyWALLCHOPSFailed, "%n", Source.Nick), "%u", Source.UserName & Source.VirtHost), "%r", "+b"))
    'Is the channel restricted, and the user not on the ACL (thus effectively +K'd)?
    ElseIf DB(DBIndexOf(Channel.Name)).Restricted And ACLIndexOf(DBIndexOf(Channel.Name), Source.Nick) < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyRestricted, "%c", Channel.Name))
        Call basFunctions.SendNumeric(Source.Nick, 473, Channel.Name + " :Cannot join channel (+i)")
        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Replace(Replace(Replace(Replies.ChanServIdentifyWALLCHOPSFailed, "%n", Source.Nick), "%u", Source.UserName & Source.VirtHost), "%r", "+b"))
    'Is the channel +A, +O, or +z, and the user is not?
    ElseIf (InStr(Channel.Modes, "A") > 0 And InStr(Source.Modes, "A") = 0) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyRestricted, "%c", Channel.Name))
        Call basFunctions.SendNumeric(Source.Nick, 519, Channel.Name + " :Cannot join channel (Admins only)")
        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Replace(Replace(Replace(Replies.ChanServIdentifyWALLCHOPSFailed, "%n", Source.Nick), "%u", Source.UserName & Source.VirtHost), "%r", "+A"))
    ElseIf (InStr(Channel.Modes, "O") > 0 And InStr(Source.Modes, "o") = 0) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyRestricted, "%c", Channel.Name))
        Call basFunctions.SendNumeric(Source.Nick, 520, Channel.Name + " :Cannot join channel (IRCops only)")
        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Replace(Replace(Replace(Replies.ChanServIdentifyWALLCHOPSFailed, "%n", Source.Nick), "%u", Source.UserName & Source.VirtHost), "%r", "+O"))
    ElseIf (InStr(Channel.Modes, "z") > 0 And InStr(Source.Modes, "z") = 0) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyRestricted, "%c", Channel.Name))
        Call basFunctions.SendNumeric(Source.Nick, 489, Channel.Name + " :Cannot join channel (+z)")
        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Replace(Replace(Replace(Replies.ChanServIdentifyWALLCHOPSFailed, "%n", Source.Nick), "%u", Source.UserName & Source.VirtHost), "%r", "+z"))
    'Is the password correct?
    ElseIf Password <> DB(DBIndexOf(Channel.Name)).Password Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.ChanServIdentifyBadPass)
        Call basFunctions.SendData(FormatString(":{0} NOTICE @{1} :{2}", Service(SVSINDEX_CHANSERV).Nick, Channel.Name, Replace(Replace(Replace(Replies.ChanServIdentifyWALLCHOPSFailed, "%n", Source.Nick), "%u", Source.UserName & Source.VirtHost), "%r", "+k")))
        Source.BadIdentifies = Source.BadIdentifies + 1
        If Source.BadIdentifies >= basMain.Config.BadPassLimit Then
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.ChanServIdentifyBadPassLimit)
            Source.KillUser Replies.KillReasonPasswordLimit, Service(SVSINDEX_CHANSERV).Nick
            Exit Sub 'Make absolutely sure we bail out.
        End If
    Else
        'All validations pass (or did I forget any?)... so mark him as identified.
        Channel.IdentifedUsers.Add Source
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServIdentifyOK, "%c", Channel.Name))
        If Channel.Members.Exists(Source) Then
            BotMode Channel, True, "+ao " + Source.Nick + " " + Source.Nick
        End If
    End If
End Sub

Public Sub Access(ByVal Source As User, ByVal Channel As Channel, ByVal Subcommand As String, Optional ByVal NickName As String = "", Optional ByVal Flags As String = "")
    Dim chptr As Long: chptr = DBIndexOf(Channel.Name)
    Dim saceptr As Long, daceptr As Long
    If chptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
        Exit Sub
    End If
    saceptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
    Select Case Subcommand
        Case "LIST"
            If HasFlagIdx(chptr, saceptr, CHANSERV_ACLREAD) Then
                'Prepare to dump the list on this guy.
                Dim idx As Long
                For idx = 0 To UBound(DB(chptr).AccessList)
                    With DB(chptr).AccessList(idx)
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, FormatString("{0} {1} {2}", .Nick, .Flags, IIf(.Lock > LOCK_NONE, "LOCKED: " + Choose(.Lock, "Normal", "Co-Founder", "Founder"), "")))
                    End With
                Next idx
            Else
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
            End If
        Case "ADD", "SET"
            'Right, this will be fun. We can only change the other dude's flags if he has a lower level than
            'us. And of course, if the sender even HAS ACLWRITE.
            If Not HasFlagIdx(chptr, saceptr, CHANSERV_ACLRW) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                Exit Sub
            End If
            'Is the target nick even registered?
            If Not IsNickRegistered(NickName) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.GeneralUnregedNick, "%n", NickName))
                Exit Sub
            End If
            daceptr = ACLIndexOf(chptr, NickName)
            'Now do a level comparison.
            If Not AccessLevelIdx(chptr, saceptr) > AccessLevelIdx(chptr, daceptr) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                Exit Sub
            End If
            'Check if the ACE is locked, and if we have the perm to lock it.
            If ACLIndexOf(chptr, NickName) > 0 Then
                If DB(chptr).AccessList(daceptr).Lock >= LOCK_LOCK And Not (HasAnyFlagIdx(chptr, saceptr, CHANSERV_LOCKACE, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(Source.Nick)) Then
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                    Exit Sub
                ElseIf DB(chptr).AccessList(daceptr).Lock >= LOCK_CFOUNDER And Not (HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(Source.Nick)) Then
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                    Exit Sub
                ElseIf DB(chptr).AccessList(daceptr).Lock >= LOCK_FOUNDER And Not HasFlagIdx(chptr, saceptr, CHANSERV_PERMFOUNDER) Then
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                    Exit Sub
                End If
            End If
            'Now check for flags the sender can't set.
            If InStr(Flags, CHANSERV_PERMFOUNDER) > 0 And HasFlagIdx(chptr, saceptr, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_PERMFOUNDER), "%r", Replace(Replace(Replies.ChanServACEIgnorePFounder, "%c", Channel.Name), "%n", NickName)))
                Flags = Replace(Flags, CHANSERV_PERMFOUNDER, "")
            ElseIf InStr(Flags, CHANSERV_PERMFOUNDER) > 0 And Not HasFlagIdx(chptr, saceptr, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_PERMFOUNDER), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_PERMFOUNDER, "")
            ElseIf InStr(Flags, CHANSERV_COFOUNDER) > 0 And Not HasFlagIdx(chptr, saceptr, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_COFOUNDER), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_COFOUNDER, "")
            ElseIf InStr(Flags, CHANSERV_ACLRW) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_ACLRW), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_ACLRW, "")
            ElseIf InStr(Flags, CHANSERV_ACLREAD) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_ACLRW, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_ACLREAD), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_ACLREAD, "")
            ElseIf InStr(Flags, CHANSERV_VOICE) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_VOICEOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_VOICE), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_VOICE, "")
            ElseIf InStr(Flags, CHANSERV_VOICEOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_HALFOP, CHANSERV_HALFOPOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_VOICEOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_VOICEOP, "")
            ElseIf InStr(Flags, CHANSERV_QUIET) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_VOICEOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_QUIET), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_QUIET, "")
            ElseIf InStr(Flags, CHANSERV_SUPERQUIET) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_HALFOP, CHANSERV_HALFOPOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_SUPERQUIET), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_SUPERQUIET, "")
            ElseIf InStr(Flags, CHANSERV_HALFOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_HALFOPOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_HALFOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_HALFOP, "")
            ElseIf InStr(Flags, CHANSERV_HALFOPOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_OP, CHANSERV_OPOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_HALFOPOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_HALFOPOP, "")
            ElseIf InStr(Flags, CHANSERV_DEHALFOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_OP, CHANSERV_OPOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_DEHALFOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_DEHALFOP, "")
            ElseIf InStr(Flags, CHANSERV_OP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_OPOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_OP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_OP, "")
            ElseIf InStr(Flags, CHANSERV_OPOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_PROTECT, CHANSERV_PROTECTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_OPOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_OPOP, "")
            ElseIf InStr(Flags, CHANSERV_DEOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_PROTECT, CHANSERV_PROTECTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_DEOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_DEOP, "")
            ElseIf InStr(Flags, CHANSERV_PROTECT) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_PROTECTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_PROTECT), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_PROTECT, "")
            ElseIf InStr(Flags, CHANSERV_PROTECTOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_OWNER, CHANSERV_OWNEROP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_PROTECTOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_PROTECTOP, "")
            ElseIf InStr(Flags, CHANSERV_OWNER) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_OWNEROP, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_OWNER), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_OWNER, "")
            ElseIf InStr(Flags, CHANSERV_OWNEROP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_OWNEROP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_OWNEROP, "")
            ElseIf InStr(Flags, CHANSERV_CANKICK) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_HALFOP, CHANSERV_HALFOPOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_CANKICK), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_CANKICK, "")
            ElseIf InStr(Flags, CHANSERV_AUTOKICK) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_BANOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_AUTOKICK), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_AUTOKICK, "")
            ElseIf InStr(Flags, CHANSERV_CANBAN) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_BANOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_CANBAN), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_CANBAN, "")
            ElseIf InStr(Flags, CHANSERV_BANOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_BANOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_BANOP, "")
            ElseIf InStr(Flags, CHANSERV_EXEMPT) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_EXEMPTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_EXEMPT), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_EXEMPT, "")
            ElseIf InStr(Flags, CHANSERV_EXEMPTOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_EXEMPTOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_EXEMPTOP, "")
            ElseIf InStr(Flags, CHANSERV_INVITE) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_INVITEOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_INVITE), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_INVITE, "")
            ElseIf InStr(Flags, CHANSERV_INVITEOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_INVITEOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_INVITEOP, "")
            ElseIf InStr(Flags, CHANSERV_MODEOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_MODEOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_MODEOP, "")
            ElseIf InStr(Flags, CHANSERV_CLEAR) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_CLEAR), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_CLEAR, "")
            ElseIf InStr(Flags, CHANSERV_TOPICOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_TOPICMAN, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_TOPICOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_TOPICOP, "")
            ElseIf InStr(Flags, CHANSERV_TOPICMAN) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_TOPICMAN), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_TOPICMAN, "")
            ElseIf InStr(Flags, CHANSERV_GETKEY) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_SETKEY, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_GETKEY), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_GETKEY, "")
            ElseIf InStr(Flags, CHANSERV_SETKEY) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_SETKEY), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_SETKEY, "")
            ElseIf InStr(Flags, CHANSERV_UNBAN) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_UNBANOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_UNBAN), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_UNBAN, "")
            ElseIf InStr(Flags, CHANSERV_UNBANOP) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_UNBANOP), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_UNBANOP, "")
            ElseIf InStr(Flags, CHANSERV_MEMOADMIN) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_MEMOADMIN), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_MEMOADMIN, "")
            ElseIf InStr(Flags, CHANSERV_BOTCOMS) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_ACLRW, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_BOTCOMS), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_BOTCOMS, "")
            ElseIf InStr(Flags, CHANSERV_BOTMODIFY) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_BOTMODIFY), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_BOTMODIFY, "")
            ElseIf InStr(Flags, CHANSERV_BOTSPEAK) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_OPOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_BOTSPEAK), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_ACLREAD, "")
            ElseIf InStr(Flags, CHANSERV_SHOWGREET) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_ACLRW, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_SHOWGREET), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_SHOWGREET, "")
            ElseIf InStr(Flags, CHANSERV_BOTNOKICK) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_BOTNOKICK), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_BOTNOKICK, "")
            ElseIf InStr(Flags, CHANSERV_INFOALL) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_INFOALL), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_INFOALL, "")
            ElseIf InStr(Flags, CHANSERV_NOSIGNKICK) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_NOSIGNKICK), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_NOSIGNKICK, "")
            ElseIf InStr(Flags, CHANSERV_SET) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_SET), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_SET, "")
            ElseIf InStr(Flags, CHANSERV_SETLOCK) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_SETLOCK), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_SETLOCK, "")
            ElseIf InStr(Flags, CHANSERV_SETLOCK) > 0 Then
                'Not implemented...
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_ACLREAD), "%r", "This flag is currently not implemented."))
                Flags = Replace(Flags, CHANSERV_ACLREAD, "")
            ElseIf InStr(Flags, CHANSERV_LOCKACE) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_LOCKACE), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_LOCKACE, "")
            ElseIf InStr(Flags, CHANSERV_LOCKLIST) > 0 And Not HasAnyFlagIdx(chptr, saceptr, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replace(Replies.ChanServACEFlagIgnored, "%n", CHANSERV_LOCKLIST), "%r", Replies.InsufficientPermissions))
                Flags = Replace(Flags, CHANSERV_LOCKLIST, "")
            End If
            'Ok we weeded out all the stuff they can't set. See if there's still anything left to set.
            If Len(Replace(Replace(Flags, "+", ""), "-", "")) = 0 Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServACENotChanged, "%n", NickName))
                Exit Sub
            End If
            'Now condense the flags.
            While (InStr(Flags, "+-") + InStr(Flags, "-+") + InStr(Flags, "--") + InStr(Flags, "++")) > 0 Or (Right(Flags, 1) = "+" Or Right(Flags, 1) = "-")
                Flags = Replace(Flags, "+-", "-")
                Flags = Replace(Flags, "-+", "+")
                Flags = Replace(Flags, "--", "-")
                Flags = Replace(Flags, "++", "+")
                If (Right(Flags, 1) = "+" Or Right(Flags, 1) = "-") Then Flags = Left(Flags, Len(Flags) - 1)
            Wend
            'Now go.
            SetFlag Channel.Name, NickName, Flags
            'Let the channel know.
            Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Replace(Replace(Replace(Replace(Replies.ChanServVerboseACLChange, "%n", Source.Nick), "%c", NickName), "%f", Flags), "%s", DB(chptr).AccessList(daceptr).Flags))
        Case "DEL"
    End Select
End Sub

Public Sub ManageMaskList(ByVal Source As User, ByVal Channel As Channel, ByVal List As String, ByVal Subcommand As String, Optional ByVal Entry As String = "", Optional ByVal Expiry As Long = 0, Optional ByVal Reason As String = "")
    Dim chptr As Long
    chptr = DBIndexOf(Channel.Name)
    If chptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
        Exit Sub
    End If
    Select Case List
        Case "AKICK": ListAKick Source, Channel, chptr, Subcommand, Entry, Expiry, Reason
        Case "EXEMPTS": ListExempt Source, Channel, chptr, Subcommand, Entry, Expiry
        Case "INVITES": ListExempt Source, Channel, chptr, Subcommand, Entry, Expiry
    End Select
End Sub

Private Sub ListAKick(ByVal Source As User, ByVal Channel As Channel, ByVal chptr As Long, ByVal Subcommand As String, Optional ByVal Entry As String = "", Optional ByVal Expiry As Long = 0, Optional ByVal Reason As String = "")
    'Permcheck.
    Dim aceptr As Long
    If chptr < 0 Then
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIIIIIIEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE.
        Call basFunctions.LogEventWithMessage(LogTypeError, Replace(Replace(Replace(Replies.SanityCheckDBIndexInvalid, "%f", "ListAKick"), "%i", chptr), "%n", "chptr"))
        '*Splat*.
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Unexpected error processing request.")
        Exit Sub
    End If
    With DB(chptr)
        aceptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
        If HasAnyFlagIdx(chptr, aceptr, CHANSERV_BANOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(Source) Then
            Dim idx As Long
            Select Case Subcommand
                Case "LIST", "VIEW"
                    On Error GoTo NoAKicks
                    For idx = 0 To UBound(.AKicks)
                        With .AKicks(idx)
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, IIf(.Lock > LOCK_NONE, Choose(.Lock, "!", "#", "@") + " ", "") + .Mask + " " + .Expiry + " " + .Reason)
                        End With
                    Next idx
NoAKicks:
                    If Err Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "No autokicks for " + Channel.Name)
                        Resume NoAKicks
                    End If
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "End of autokick list for " + Channel.Name)
                Case "ADD"
                    If AKickIndexOf(chptr, Entry) < 0 Then
                        If InStr("!#@", Left(Entry, 1)) > 0 Then
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.IncorrectParam)
                        Else
                            AddAKick chptr, Entry, Reason, Expiry
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "AKick " + Entry + " added. Use /chanserv AKICK " + Channel.Name + " ENFORCE to remove any users on the channel matching the autokick.")
                        End If
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Entry " + Entry + " already exists. Use /chanserv AKICK " + Channel.Name + " ENFORCE to remove any users on the channel matching the autokick.")
                    End If
                Case "DEL"
                    If AKickIndexOf(chptr, Entry) < 0 Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Entry " + Entry + " not found.")
                    Else
                        DelAKick chptr, Entry
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Entry " + Entry + " removed.")
                    End If
                Case "STICK", "UNSTICK"
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Sorry, STICK and UNSTICK are not functional at this time.")
                Case "ENFORCE"
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "AKick for " + Channel.Name + " - " + CStr(RunAKickCheck(Channel)) + " user(s) affected.")
            End Select
        Else
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
        End If
    End With
End Sub

Private Sub ListExempt(ByVal Source As User, ByVal Channel As Channel, ByVal chptr As Long, ByVal Subcommand As String, Optional ByVal Entry As String = "", Optional ByVal Expiry As Long = 0)
    'Permcheck.
    Dim aceptr As Long
    If chptr < 0 Then
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIIIIIIEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE.
        Call basFunctions.LogEventWithMessage(LogTypeError, Replace(Replace(Replace(Replies.SanityCheckDBIndexInvalid, "%f", "ListExempt"), "%i", chptr), "%n", "chptr"))
        '*Splat*.
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Unexpected error processing request.")
        Exit Sub
    End If
    With DB(chptr)
        aceptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
        If HasAnyFlagIdx(chptr, aceptr, CHANSERV_EXEMPTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(Source) Then
            Dim idx As Long
            Select Case Subcommand
                Case "LIST", "VIEW"
                    On Error GoTo NoExempts
                    For idx = 0 To UBound(.Exempts)
                        With .Exempts(idx)
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, IIf(.Lock > LOCK_NONE, Choose(.Lock, "!", "#", "@") + " ", "") + .Mask + " " + .Expiry)
                        End With
                    Next idx
NoExempts:
                    If Err Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "No exempts for " + Channel.Name)
                        Resume NoExempts
                    End If
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "End of exempt list for " + Channel.Name)
                Case "ADD"
                    If ExemptIndexOf(chptr, Entry) < 0 Then
                        If InStr("!#@", Left(Entry, 1)) > 0 Then
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.IncorrectParam)
                        Else
                            AddExempt chptr, Entry, Expiry
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Exempt " + Entry + " added.")
                        End If
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Entry " + Entry + " already exists.")
                    End If
                Case "DEL"
                    If ExemptIndexOf(chptr, Entry) < 0 Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Entry " + Entry + " not found.")
                    Else
                        DelExempt chptr, Entry
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Entry " + Entry + " removed.")
                    End If
                Case "STICK", "UNSTICK"
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Sorry, STICK and UNSTICK are not functional at this time.")
            End Select
        Else
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
        End If
    End With
End Sub

Private Sub ListInvite(ByVal Source As User, ByVal Channel As Channel, ByVal chptr As Long, ByVal Subcommand As String, Optional ByVal Entry As String = "", Optional ByVal Expiry As Long = 0)
    'Permcheck.
    Dim aceptr As Long
    If chptr < 0 Then
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIIIIIIEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE.
        Call basFunctions.LogEventWithMessage(LogTypeError, Replace(Replace(Replace(Replies.SanityCheckDBIndexInvalid, "%f", "ListInvite"), "%i", chptr), "%n", "chptr"))
        '*Splat*.
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Unexpected error processing request.")
        Exit Sub
    End If
    With DB(chptr)
        aceptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
        If HasAnyFlagIdx(chptr, aceptr, CHANSERV_INVITEOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(Source) Then
            Dim idx As Long
            Select Case Subcommand
                Case "LIST", "VIEW"
                    On Error GoTo NoInvites
                    For idx = 0 To UBound(.Invites)
                        With .Invites(idx)
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, IIf(.Lock > LOCK_NONE, Choose(.Lock, "!", "#", "@") + " ", "") + .Mask + " " + .Expiry)
                        End With
                    Next idx
NoInvites:
                    If Err Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "No Invites for " + Channel.Name)
                        Resume NoInvites
                    End If
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "End of Invite list for " + Channel.Name)
                Case "ADD"
                    If InviteIndexOf(chptr, Entry) < 0 Then
                        If InStr("!#@", Left(Entry, 1)) > 0 Then
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.IncorrectParam)
                        Else
                            AddInvite chptr, Entry, Expiry
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Invite " + Entry + " added.")
                        End If
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Entry " + Entry + " already exists.")
                    End If
                Case "DEL"
                    If InviteIndexOf(chptr, Entry) < 0 Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Entry " + Entry + " not found.")
                    Else
                        DelInvite chptr, Entry
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Entry " + Entry + " removed.")
                    End If
                Case "STICK", "UNSTICK"
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Sorry, STICK and UNSTICK are not functional at this time.")
            End Select
        Else
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
        End If
    End With
End Sub

Public Function RunAKickCheck(ByVal chptr As Channel) As Long
    'EXEMPT Check.
    Dim idx As Long, dbptr As Long, cptr As ChannelMember, nCount As Long
    dbptr = DBIndexOf(chptr.Name)
    On Error GoTo NoExempts
    For idx = 0 To UBound(DB(dbptr).Exempts)
        With DB(dbptr).Exempts(idx)
            'Now check if any users match this exempt, and if so, activate it.
            For Each cptr In chptr.Members
                If NUHMaskIsMatch(cptr.Member, .Mask) Then
                    'Matches, so activate it.
                    BotMode chptr, True, "+e " + .Mask
                    Exit For
                End If
            Next cptr
        End With
    Next idx
NoExempts:
    If Err Then Resume NoExempts
    On Error GoTo NoAKicks
    'Now AKICK Check.
    Dim bExempted As Boolean, ex As Variant
    For idx = 0 To UBound(DB(dbptr).AKicks)
        With DB(dbptr).AKicks(idx)
            For Each cptr In chptr.Members
                If NUHMaskIsMatch(cptr.Member, .Mask) Then
                    bExempted = False
                    For Each ex In chptr.Excepts
                        If NUHMaskIsMatch(cptr.Member, ex) Then
                            bExempted = True
                            Exit For
                        End If
                    Next ex
                    bExempted = bExempted Or HasAnyFlag(chptr.Name, cptr.Member.IdentifiedToNick, CHANSERV_EXEMPT, CHANSERV_EXEMPTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or chptr.IdentifedUsers.Exists(cptr.Member)
                    If Not bExempted Then
                        'AKicked, and not exempted, so boot 'em out.
                        BotMode chptr, True, "+b " & .Mask
                        BotKick chptr, True, cptr.Member, Replace(Replace(IIf(.Expiry > 0, Replies.ChanServAKICKTemp, Replies.ChanServAKICKPerm), "%c", chptr.Name), "%r", .Reason)
                        nCount = nCount + 1
                        basFunctions.SendNumeric cptr.Member.Nick, 474, chptr.Name & " :Cannot join channel (+b)"
                    End If
                End If
            Next cptr
        End With
    Next idx
NoAKicks:
    RunAKickCheck = nCount
End Function

Public Sub AKickCheckUser(ByVal chptr As Channel, ByVal cptr As User)
    Dim idx As Long, dbptr As Long
    dbptr = DBIndexOf(chptr.Name)
    On Error GoTo NoExempts
    For idx = 0 To UBound(DB(dbptr).Exempts)
        With DB(dbptr).Exempts(idx)
            'Now check if any users match this exempt, and if so, activate it.
            If NUHMaskIsMatch(cptr, .Mask) Then
                'Matches, so activate it.
                BotMode chptr, True, "+e " + .Mask
                Exit For
            End If
        End With
    Next idx
NoExempts:
    If Err Then Resume NoExempts
    On Error GoTo NoAKicks
    'Now AKICK Check.
    Dim bExempted As Boolean, ex As Variant
    For idx = 0 To UBound(DB(dbptr).AKicks)
        With DB(dbptr).AKicks(idx)
            If NUHMaskIsMatch(cptr, .Mask) Then
                bExempted = False
                For Each ex In chptr.Excepts
                    If NUHMaskIsMatch(chptr, ex) Then
                        bExempted = True
                        Exit For
                    End If
                Next ex
                bExempted = bExempted Or HasAnyFlag(chptr.Name, cptr.IdentifiedToNick, CHANSERV_EXEMPT, CHANSERV_EXEMPTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or chptr.IdentifedUsers.Exists(cptr)
                If Not bExempted Then
                    'AKicked, and not exempted, so boot 'em out.
                    BotMode chptr, True, "+b " & .Mask
                    BotKick chptr, True, cptr, Replace(Replace(IIf(.Expiry > 0, Replies.ChanServAKICKTemp, Replies.ChanServAKICKPerm), "%c", chptr.Name), "%r", .Reason)
                    basFunctions.SendNumeric cptr.Nick, 474, chptr.Name & " :Cannot join channel (+b)"
                    Exit Sub
                End If
            End If
        End With
    Next idx
NoAKicks:
End Sub

Public Sub Invite(ByVal Source As User, ByVal Channel As Channel, ByVal Nick As User)
    Dim chptr As Long, aceptr As Long
    chptr = DBIndexOf(Channel.Name)
    If chptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
        Exit Sub
    End If
    aceptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
    'Now do they have permission, or are they on the INVITE list?
    Dim idx As Long, bInvited As Boolean
    If Nick Is Source Then
        bInvited = HasAnyFlagIdx(chptr, aceptr, CHANSERV_INVITE, CHANSERV_INVITEOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(Source)
        If Not bInvited Then
            On Error GoTo NoInvites
            For idx = 0 To UBound(DB(chptr).Invites)
                With DB(chptr).Invites(idx)
                    If NUHMaskIsMatch(Nick, .Mask) Then
                        'Activate it if we can.
                        BotMode Channel, False, "+I " + .Mask
                        bInvited = True
                    End If
                End With
            Next idx
NoInvites:
            If Err Then Resume NoInvites
            On Error GoTo 0
        End If
    Else
        bInvited = HasAnyFlagIdx(chptr, aceptr, CHANSERV_INVITEOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(Source)
    End If
    If Not bInvited Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
    Else
        'Now we do the invite.
        If Not Source Is Nick Then
            Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Replace(Replace(Replies.ChanServVerboseInvite, "%n", Source.Nick), "%c", Nick.Nick))
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Nick.Nick, Replace(Replace(Replies.ChanServInvitation, "%n", Source.Nick), "%c", Channel.Name))
        End If
        Call basFunctions.SendData(FormatString(":{0} INVITE {1} {2}", Service(SVSINDEX_CHANSERV).Nick, Nick.Nick, Channel.Name))
    End If
End Sub

Public Sub Unban(ByVal Source As User, ByVal Channel As Channel, ByVal User As User)
    Dim chptr As Long, aceptr As Long
    chptr = DBIndexOf(Channel.Name)
    If chptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
        Exit Sub
    End If
    aceptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
    'Now do they have permission, or are they on the EXEMPT list?
    If Source Is User Then
        Dim idx As Long, bExempted As Boolean, bOk As Boolean
        For idx = 0 To UBound(DB(chptr).Exempts)
            With DB(chptr).Exempts(idx)
                If NUHMaskIsMatch(User, .Mask) Then
                    'Activate it if we can.
                    BotMode Channel, False, "+e " + .Mask
                    bExempted = True
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, User.Nick, Replace(Replies.ChanServUnbanExemptEntry, "%e", .Mask))
                End If
            End With
        Next idx
        If Not bExempted And (HasAnyFlagIdx(chptr, aceptr, CHANSERV_EXEMPT, CHANSERV_EXEMPTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(Source)) Then
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, User.Nick, Replies.ChanServUnbanExemptFlag)
            BotMode Channel, False, "+e *!*@" + Source.HostName
        End If
    End If
    If User Is Source Then
        bOk = HasAnyFlagIdx(chptr, aceptr, CHANSERV_UNBAN, CHANSERV_UNBANOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(Source)
    Else
        bOk = HasAnyFlagIdx(chptr, aceptr, CHANSERV_UNBANOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(Source)
    End If
    If Not (bOk Or bExempted) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
    Else
        'Now we do the unban.
        If Not Source Is User Then
            Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Replace(Replace(Replies.ChanServVerboseUnban, "%n", Source.Nick), "%c", User.Nick))
        End If
        Dim v As Variant, nBans As Long
        nBans = 0
        For Each v In Channel.Bans
            If NUHMaskIsMatch(User, v) Then
                nBans = nBans + 1
                BotMode Channel, False, "-b " + v
            End If
        Next v
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServUnbanBansRemoved, "%n", nBans))
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, User.Nick, Replace(Replace(Replies.ChanServNowUnbanned, "%n", Source.Nick), "%c", Channel.Name))
    End If
End Sub

Public Sub StatusChange(ByVal Source As User, ByVal Channel As Channel, ByVal What As String, ByVal Target As User)
    Dim chptr As Long, saceptr As Long, daceptr As Long
    Dim Flag As String, change As String
    chptr = DBIndexOf(Channel.Name)
    If chptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
        Exit Sub
    End If
    saceptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
    daceptr = ACLIndexOf(chptr, Target.IdentifiedToNick)
    basFunctions.Notice Service(SVSINDEX_CHANSERV).Nick, Channel.Name, Source.Nick + " used " + What + " for " + Target.Nick
    Select Case What
        Case "VOICE"
            If Source.IdentifiedToNick = Target.IdentifiedToNick Then
                Flag = CHANSERV_VOICE + CHANSERV_VOICEOP
            Else
                Flag = CHANSERV_VOICEOP
            End If
            change = "+v"
        Case "DEVOICE"
            If Source.IdentifiedToNick = Target.IdentifiedToNick Then
                Flag = CHANSERV_VOICE + CHANSERV_VOICEOP
            Else
                Flag = CHANSERV_VOICEOP
            End If
            change = "-v"
        Case "HALFOP"
            If Source.IdentifiedToNick = Target.IdentifiedToNick Then
                Flag = CHANSERV_HALFOP + CHANSERV_HALFOPOP
            Else
                Flag = CHANSERV_HALFOPOP
            End If
            change = "+h"
        Case "DEHALFOP"
            If Source.IdentifiedToNick = Target.IdentifiedToNick Then
                Flag = CHANSERV_HALFOP + CHANSERV_HALFOPOP
            Else
                Flag = CHANSERV_HALFOPOP
            End If
            change = "-h"
        Case "OP"
            If Source.IdentifiedToNick = Target.IdentifiedToNick Then
                Flag = CHANSERV_OP + CHANSERV_OPOP
            Else
                Flag = CHANSERV_OPOP
            End If
            change = "+o"
        Case "DEOP"
            If Source.IdentifiedToNick = Target.IdentifiedToNick Then
                Flag = CHANSERV_OP + CHANSERV_OPOP
            Else
                Flag = CHANSERV_OPOP
            End If
            change = "-o"
        Case "PROTECT"
            If Source.IdentifiedToNick = Target.IdentifiedToNick Then
                Flag = CHANSERV_PROTECT + CHANSERV_PROTECT
            Else
                Flag = CHANSERV_PROTECTOP
            End If
            change = "+a"
        Case "DEPROTECT"
            If Source.IdentifiedToNick = Target.IdentifiedToNick Then
                Flag = CHANSERV_PROTECT + CHANSERV_PROTECTOP
            Else
                Flag = CHANSERV_PROTECTOP
            End If
            change = "-a"
        Case "OWNER"
            If Source.IdentifiedToNick = Target.IdentifiedToNick Then
                Flag = CHANSERV_OWNER + CHANSERV_OWNEROP
            Else
                Flag = CHANSERV_OWNEROP
            End If
            change = "+q"
        Case "DEOWNER"
            If Source.IdentifiedToNick = Target.IdentifiedToNick Then
                Flag = CHANSERV_OWNER + CHANSERV_OWNEROP
            Else
                Flag = CHANSERV_OWNEROP
            End If
            change = "-q"
        Case Else: Error 5
        'End Case
    End Select
    Dim aclsource As Long, acltarget As Long
    aclsource = AccessLevelIdx(chptr, saceptr)
    acltarget = AccessLevelIdx(chptr, daceptr)
    If Channel.IdentifedUsers.Exists(Source) And aclsource < 11 Then aclsource = 11
    If Channel.IdentifedUsers.Exists(Target) And acltarget < 11 Then acltarget = 11
    If HasFlagIdx(chptr, saceptr, "-" + CHANSERV_PERMFOUNDER + CHANSERV_COFOUNDER + Flag) And Not Channel.IdentifedUsers.Exists(Source) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
    ElseIf aclsource < acltarget And Left(change, 1) = "-" Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
    Else
        'I guess we can do the change then.
        BotMode Channel, False, change + " " + Target.Nick
    End If
End Sub

Public Sub StandardList(ByVal Source As User, ByVal Channel As Channel, ByVal What As String, ByVal Target As String)
    basFunctions.Notice Service(SVSINDEX_CHANSERV).Nick, Channel.Name, Source.Nick + " used " + What + " for " + Target
    Select Case What
        Case "VOP"
            Access Source, Channel, "SET", Target, "+" + CHANSERV_VOPDEFAULT
        Case "HOP"
            Access Source, Channel, "SET", Target, "+" + CHANSERV_HOPDEFAULT
        Case "AOP"
            Access Source, Channel, "SET", Target, "+" + CHANSERV_AOPDEFAULT
        Case "SOP"
            Access Source, Channel, "SET", Target, "+" + CHANSERV_SOPDEFAULT
        Case "CFOUNDER"
            Access Source, Channel, "SET", Target, "+" + CHANSERV_CFOUNDERDEFAULT
        Case Else: Error 5
    End Select
End Sub

Public Sub BootUser(ByVal Source As User, ByVal Channel As Channel, ByVal Target As User, ByVal Message As String, Optional ByVal BanType As Integer = -1)
    Dim chptr As Long, saceptr As Long, daceptr As Long
    chptr = DBIndexOf(Channel.Name)
    If chptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
        Exit Sub
    End If
    saceptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
    daceptr = ACLIndexOf(chptr, Target.IdentifiedToNick)
    Dim aclsource As Long, acltarget As Long
    aclsource = AccessLevelIdx(chptr, saceptr)
    acltarget = AccessLevelIdx(chptr, daceptr)
    If Channel.IdentifedUsers.Exists(Source) And aclsource < 11 Then aclsource = 11
    If Channel.IdentifedUsers.Exists(Target) And acltarget < 11 Then acltarget = 11
    If BanType < 0 Then
        If HasFlagIdx(chptr, saceptr, "-" + CHANSERV_PERMFOUNDER + CHANSERV_COFOUNDER + CHANSERV_CANKICK) And Not Channel.IdentifedUsers.Exists(Source) Then
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
        ElseIf Source.IdentifiedToNick <> Target.IdentifiedToNick And (aclsource < acltarget) Then
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
        Else
            BotKick Channel, False, Target, IIf(Not HasFlagIdx(chptr, saceptr, CHANSERV_NOSIGNKICK), Source.IdentifiedToNick + ":", "") + Message
        End If
    Else
        If HasFlagIdx(chptr, saceptr, "-" + CHANSERV_PERMFOUNDER + CHANSERV_COFOUNDER + CHANSERV_CANBAN + CHANSERV_BANOP) And Not Channel.IdentifedUsers.Exists(Source) Then
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
        ElseIf Source.IdentifiedToNick <> Target.IdentifiedToNick And (aclsource < acltarget) Then
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
        Else
            Dim Mask As String
            Mask = basFunctions.Mask(Target.Nick + "!" + Target.UserName + "@" + IIf(Target.VirtHost <> "", Target.VirtHost, Target.HostName), BanType)
            BotMode Channel, False, "+b " + Mask
            BotKick Channel, False, Target, IIf(Not HasFlagIdx(chptr, saceptr, CHANSERV_NOSIGNKICK), Source.IdentifiedToNick + ":", "") + Message
        End If
    End If
End Sub

Public Sub Topic(ByVal Source As User, ByVal Channel As Channel, ByVal NewTopic As String)
    Dim chptr As Long, cptr As Long
    chptr = DBIndexOf(Channel.Name)
    If chptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
        Exit Sub
    End If
    cptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_TOPICMAN, CHANSERV_TOPICOP) Or Channel.IdentifedUsers.Exists(Source) Then
        'Can change the topic.
        BotTopic Channel, NewTopic, Source.IdentifiedToNick, basUnixTime.GetTime
    Else
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
    End If
End Sub

Public Sub Mode(ByVal Source As User, ByVal Channel As Channel, ByVal ModeChange As String)
    Dim chptr As Long, cptr As Long
    chptr = DBIndexOf(Channel.Name)
    If chptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
        Exit Sub
    End If
    cptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_MODEOP) Or Channel.IdentifedUsers.Exists(Source) Then
        'Can change the modes.
        BotMode Channel, False, ModeChange
    Else
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
    End If
End Sub

Public Sub ChannelSetting(ByVal Source As User, ByVal Channel As Channel, ByVal Setting As String)
    Dim chptr As Long, cptr As Long, bSet As Boolean
    chptr = DBIndexOf(Channel.Name)
    If chptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
        Exit Sub
    End If
    cptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
    If Not (HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_SET) Or Channel.IdentifedUsers.Exists(Source)) Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
        Exit Sub
    End If
    If Left(Setting, 1) = "+" Or Left(Setting, 1) = "-" Then
        'SET #channel +OPTION1 +OPTION2 -OPTION3 only legal for boolean options
        Dim vWords As Variant, vWord As Variant
        vWords = Split(Setting, " ")
        For Each vWord In vWords
            Dim sSetting As String
            If Left(vWord, 1) = "+" Then
                bSet = True
            ElseIf Left(vWord, 1) = "-" Then
                bSet = False
            Else
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": No + or - prefix.")
                GoTo GoNext
            End If
            sSetting = Mid(vWord, 2)
            Select Case UCase(sSetting)
                Case "SECUREOPS"
                    'Should require the op manager flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_OPOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).SecureOps = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "SecureOps for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " SecureOps.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "SECUREHALFOPS"
                    'Should require the halfop manager flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_HALFOPOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).SecureHalfOps = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "SecureHalfOps for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " SecureHalfOps.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "SECUREVOICES"
                    'Should require the voice manager flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_VOICEOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).SecureVoices = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "SecureVoices for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " SecureVoices.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "RESTRICTED"
                    'Should require the ban manager flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_BANOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).Restricted = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Restricted for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " Restricted.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "SECURE"
                    DB(chptr).Secure = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Secure for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " Secure.")
                Case "LEAVEOPS"
                    'Should require the op manager flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_BANOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).LeaveOps = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "LeaveOps for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " LeaveOps.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "TOPICLOCK"
                    'Should require the topic manager flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_TOPICMAN) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).TopicLock = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "TopicLock for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " TopicLock.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "STRICTSTATUS"
                    'Should require the mode op flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_MODEOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).StrictStatus = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "StrictStatus for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " StrictStatus.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "STRICTLIST"
                    'Should require the mode op flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_MODEOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).StrictList = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "StrictList for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " StrictList.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "LEARNBANS"
                    'Should require the ban manager flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_BANOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).LearnBans = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "LearnBans for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " LearnBans.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "FORGETBANS"
                    'Should require the ban manager flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_BANOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).ForgetBans = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "ForgetBans for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " ForgetBans.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "GIVE"
                    'Should require the ban manager flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_BANOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).Give = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Give for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " Give.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "STRICTMODE"
                    'Should require the mode op flag as well.
                    If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_MODEOP) Or Channel.IdentifedUsers.Exists(Source) Then
                        DB(chptr).StrictMode = bSet
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "StrictMode for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " StrictMode.")
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                    End If
                Case "MLOCK"
                    If bSet Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientParameters)
                    Else
                        If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_MODEOP) Or Channel.IdentifedUsers.Exists(Source) Then
                            DB(chptr).MLock = "+"
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "MLock for " + Channel.Name + " set to +")
                            Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " changed the MLock to +.")
                        Else
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientPermissions)
                        End If
                    End If
                Case "PASSWORD"
                    If bSet Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientParameters)
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": Password may not be unset.")
                    End If
                Case "FOUNDER"
                    If bSet Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientParameters)
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": Founder may not be unset.")
                    End If
                Case "SUCCESSOR"
                    If bSet Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientParameters)
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": Successor may not be unset.")
                    End If
                Case "DESCRIPTION"
                    If bSet Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": " + Replies.InsufficientParameters)
                    Else
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": Description may not be unset.")
                    End If
                Case Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Ignoring token " + vWord + ": Unknown SET option or not a boolean SET option.")
                'End Case
            End Select
GoNext:
        Next vWord
    Else
        'Normal format: SET #channel OPTION VALUE
        Dim sOption As String, sValue As String
        If InStr(Setting, " ") = 0 Then
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientParameters)
            Exit Sub
        End If
        sOption = Split(Setting, " ", 2)(0)
        sValue = Split(Setting, " ", 2)(1)
        'For anything that needs it.
        Select Case UCase(sValue)
            Case "YES", "ON", "1", "TRUE"
                bSet = True
            Case "NO", "OFF", "0", "FALSE"
                bSet = False
            Case Else
                bSet = False
            'End Case
        End Select
        Select Case UCase(sOption)
            Case "SECUREOPS"
                'Should require the op manager flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_OPOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).SecureOps = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "SecureOps for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " SecureOps.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "SECUREHALFOPS"
                'Should require the halfop manager flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_HALFOPOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).SecureHalfOps = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "SecureHalfOps for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " SecureHalfOps.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "SECUREVOICES"
                'Should require the voice manager flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_VOICEOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).SecureVoices = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "SecureVoices for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " SecureVoices.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "RESTRICTED"
                'Should require the ban manager flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_BANOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).Restricted = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Restricted for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " Restricted.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "SECURE"
                DB(chptr).Secure = bSet
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Secure for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " Secure.")
            Case "LEAVEOPS"
                'Should require the op manager flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_BANOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).LeaveOps = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "LeaveOps for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " LeaveOps.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "TOPICLOCK"
                'Should require the topic manager flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_TOPICMAN) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).TopicLock = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "TopicLock for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " TopicLock.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "STRICTSTATUS"
                'Should require the mode op flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_MODEOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).StrictStatus = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "StrictStatus for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " StrictStatus.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "STRICTLIST"
                'Should require the mode op flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_MODEOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).StrictList = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "StrictList for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " StrictList.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "LEARNBANS"
                'Should require the ban manager flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_BANOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).LearnBans = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "LearnBans for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " LearnBans.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "FORGETBANS"
                'Should require the ban manager flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_BANOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).ForgetBans = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "ForgetBans for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " ForgetBans.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "GIVE"
                'Should require the ban manager flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_BANOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).Give = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Give for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " Give.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "STRICTMODE"
                'Should require the mode op flag as well.
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_MODEOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    DB(chptr).StrictMode = bSet
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "StrictMode for " + Channel.Name + " is now " + IIf(bSet, "on", "off") + ".")
                    Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " turned " + IIf(bSet, "on", "off") + " StrictMode.")
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "MLOCK"
                If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER, CHANSERV_COFOUNDER, CHANSERV_MODEOP) Or Channel.IdentifedUsers.Exists(Source) Then
                    If Not ValidMLock(Source, sValue) Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "The new MLOCK is invalid.")
                    Else
                        DB(chptr).MLock = sValue
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "MLock for " + Channel.Name + " set to " + sValue)
                        Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, Source.Nick + " changed the MLock to " + sValue)
                    End If
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "PASSWORD"
                If HasFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER) Then
                    DB(chptr).Password = sValue
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Password changed to " + sValue)
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissionsAbusive)
                End If
            Case "FOUNDER"
                If HasFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER) Then
                    If DBIndexOf(sValue) < 0 Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Nick " + sValue + " is not registered.")
                    Else
                        SetFlag Channel.Name, sValue, "+F"
                        SetFlag Channel.Name, Source.IdentifiedToNick, "-F+f"
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Founder changed to " + sValue + " - You have been moved to cofounder access.")
                    End If
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissionsAbusive)
                End If
            Case "SUCCESSOR"
                If HasFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER) Then
                    If DBIndexOf(sValue) < 0 Then
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Nick " + sValue + " is not registered.")
                    Else
                        DB(chptr).Successor = sValue
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Successor changed to " + sValue)
                    End If
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case "DESCRIPTION"
                If HasFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER) Then
                    DB(chptr).Description = sValue
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Description changed to " + sValue)
                Else
                    Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions)
                End If
            Case Else
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Unknown SET option or not a boolean SET option.")
            'End Case
        End Select
    End If
End Sub

Public Function ValidMLock(ByVal Source As User, ByVal MLock As String) As Boolean
    On Error Resume Next
    'Now parse the mlock.
    'The mlock is formatted as <binaryflags> [[<paramflags> <params>]]
    Dim m() As String
    m = Split(MLock, " ")
    Dim bSet As Boolean
    Dim idx As Long, ch As String * 1
    For idx = 1 To Len(m(0))
        ch = Mid(m(0), idx, 1)
        If ch = "+" Then
            bSet = True
        ElseIf ch = "-" Then
            bSet = False
        ElseIf ch = "r" Then
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Mode +r may not be mlocked.")
            ValidMLock = False
            Exit Function
        ElseIf bSet And ch = "l" Then
            'OK.
        ElseIf Not bSet And InStr(1, Split(basMain.ChannelModes2, ",", 2)(1), ch, vbBinaryCompare) Then
            '- and a Type B, C, or D mode.
            'OK.
        ElseIf bSet And InStr(1, Split(basMain.ChannelModes2, ",")(3), ch, vbBinaryCompare) Then
            '+ and a Type D mode.
            'OK.
        Else
            '+ and a Type B or C mode, or +/- and a Type A mode.
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "A parametered mode is illegally present in the unparametered mode section. Type B or C modes may only appear in an unset section with the exception of +l. To set these modes, use the parametered mode section of the MLOCK. Type A modes may not be mlocked. To set these, use the AKICK, EXEMPTS, or INVITES commands.")
            ValidMLock = False
            Exit Function
        End If
    Next idx
    Dim Modes As String, idx2 As Long
    For idx = 1 To UBound(m)
        Modes = m(idx)
        For idx2 = 1 To Len(Modes)
            ch = Mid(Modes, idx2, 1)
            If ch = "+" Then
            ElseIf ch = "-" Then
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "May not use - in the parametered section. To mlock a Type B or C mode OFF, use it with a - in the unparametered section.")
                ValidMLock = False
                Exit Function
            ElseIf InStr(1, Split(basMain.ChannelModes2, ",")(1) & Split(basMain.ChannelModes2, ",")(2), ch, vbBinaryCompare) Then
                'Eat a parameter.
                idx = idx + 1
            ElseIf InStr(1, Split(basMain.ChannelModes2, ",")(3), ch, vbBinaryCompare) Then
                'Bad char.
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "May not use Type D modes in the parametered section. To MLOCK this mode, use the unparametered section.")
                ValidMLock = False
                Exit Function
            ElseIf InStr(1, Split(basMain.ChannelModes2, ",")(0), ch, vbBinaryCompare) Then
                'Bad char.
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Type A modes may not be MLOCKed.")
                ValidMLock = False
                Exit Function
            End If
        Next idx2
    Next idx
End Function

Public Sub LockChange(ByVal Source As User, ByVal Channel As Channel, ByVal Locking As Boolean, ByVal SubLock As String, Optional ByVal Entry As String = "")

End Sub

Public Sub Clear(ByVal Source As User, ByVal Channel As Channel, ByVal What As String)
    'Not doing access level checks. Give CLEAR access with care.
    If Not HasAnyFlag(Channel.Name, Source.IdentifiedToNick, CHANSERV_CLEAR, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
        SendMessage Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions
        Exit Sub
    End If
    Select Case What
        Case "USERS"
            If Not HasAnyFlag(Channel.Name, Source.IdentifiedToNick, CHANSERV_CANKICK, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                SendMessage Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions
                Exit Sub
            End If
            'Don't want people rejoining too quickly.
            Channel.SetChannelModes Service(SVSINDEX_CHANSERV).Nick, "+iKlb 1 *!*@*"
            While Channel.Members.Count > 0
                Channel.KickUser Service(SVSINDEX_CHANSERV).Nick, Channel.Members(0).Member, "CLEAR USERS from " + Source.Nick
            Wend
            Channel.SetChannelModes Service(SVSINDEX_CHANSERV).Nick, "-iKlb *!*@*"
            TermChannel Channel
        Case "BANS"
            If Not HasAnyFlag(Channel.Name, Source.IdentifiedToNick, CHANSERV_CLEAR, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                SendMessage Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions
                Exit Sub
            End If
            Notice Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, "Clearing Bans by request of " + Source.Nick
            SendData FormatString(":{0} SVSMODE {1} -b", Service(SVSINDEX_CHANSERV).Nick, Channel.Name)
        Case "EXEMPTS"
            If Not HasAnyFlag(Channel.Name, Source.IdentifiedToNick, CHANSERV_CLEAR, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                SendMessage Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions
                Exit Sub
            End If
            Notice Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, "Clearing Exempts by request of " + Source.Nick
            SendData FormatString(":{0} SVSMODE {1} -e", Service(SVSINDEX_CHANSERV).Nick, Channel.Name)
        Case "INVITES"
            If Not HasAnyFlag(Channel.Name, Source.IdentifiedToNick, CHANSERV_CLEAR, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                SendMessage Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions
                Exit Sub
            End If
            Notice Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, "Clearing Invites by request of " + Source.Nick
            SendData FormatString(":{0} SVSMODE {1} -I", Service(SVSINDEX_CHANSERV).Nick, Channel.Name)
        Case "OPS"
            If Not HasAnyFlag(Channel.Name, Source.IdentifiedToNick, CHANSERV_CLEAR, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                SendMessage Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions
                Exit Sub
            End If
            Notice Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, "Clearing Ops by request of " + Source.Nick
            SendData FormatString(":{0} SVSMODE {1} -qao", Service(SVSINDEX_CHANSERV).Nick, Channel.Name)
        Case "HALFOPS"
            If Not HasAnyFlag(Channel.Name, Source.IdentifiedToNick, CHANSERV_CLEAR, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                SendMessage Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions
                Exit Sub
            End If
            Notice Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, "Clearing HalfOps by request of " + Source.Nick
            SendData FormatString(":{0} SVSMODE {1} -h", Service(SVSINDEX_CHANSERV).Nick, Channel.Name)
        Case "VOICES"
            If Not HasAnyFlag(Channel.Name, Source.IdentifiedToNick, CHANSERV_CLEAR, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                SendMessage Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions
                Exit Sub
            End If
            Notice Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, "Clearing Voices by request of " + Source.Nick
            SendData FormatString(":{0} SVSMODE {1} -b", Service(SVSINDEX_CHANSERV).Nick, Channel.Name)
        Case "MODES"
            If Not HasAnyFlag(Channel.Name, Source.IdentifiedToNick, CHANSERV_CLEAR, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then
                SendMessage Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissions
                Exit Sub
            End If
            Notice Service(SVSINDEX_CHANSERV).Nick, "@" + Channel.Name, "Clearing Binary Modes by request of " + Source.Nick
            BotMode Channel, False, "-l" + Split(basMain.ChannelModes2, ",")(3) + "+r"
    End Select
End Sub

Public Sub Drop(ByVal Source As User, ByVal Channel As Channel, Optional ByVal ConfirmationCode As String)
    'Dropping the channel may only be done by the founder :) .
    Dim chptr As Long, cptr As Long
    chptr = DBIndexOf(Channel.Name)
    If chptr < 0 Then
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replace(Replies.ChanServChannelNotRegistered, "%c", Channel.Name))
        Exit Sub
    End If
    cptr = ACLIndexOf(chptr, Source.IdentifiedToNick)
    Dim ccode As String
    'Confirmation code is computed as an MD5 of this string:
    'ChannelName SenderNick SenderAccount ChannelPassword
    ccode = MD5.Digest(Channel.Name + " " + Source.Nick + " " + Source.IdentifiedToNick + " " + DB(chptr).Password)
    If HasFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER) Then
        If ConfirmationCode = "" Then
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "This operation is NOT undoable! To confirm the deregistration of your channel, please type the following command: /msg " + Service(SVSINDEX_CHANSERV).Nick + "@" + basMain.Config.ServerName + " DROP " + Channel.Name + " " + ccode)
            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "Note that if you change your nick, identify as another user, or change the channel password, this code will become invalid. Also, this code is not valid for any other channel.")
        Else
            If ConfirmationCode = ccode Then
                'Do the unregistration.
                TermChannel Channel
                Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, Channel.Name, "This channel is no longer operated by " + Service(SVSINDEX_CHANSERV).Nick)
                BotMode Channel, True, "-r"
                Dim idx As Long
                For idx = chptr + 1 To UBound(DB)
                    DB(idx - 1) = DB(idx)
                Next idx
                ReDim Preserve DB(UBound(DB) - 1)
                DoMLOCK Channel, False
            Else
                Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, "The confirmation code is incorrect.")
                'We should somehow invalidate the correct code... I think scramble the password, but hmmm.
            End If
        End If
    Else
        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Source.Nick, Replies.InsufficientPermissionsAbusive)
    End If
End Sub

Public Sub Forbid(ByVal Source As User, ByVal Channel As Channel, ByVal Reason As String)

End Sub

Public Sub Suspend(ByVal Source As User, ByVal Channel As Channel, ByVal Reason As String)

End Sub

Public Sub Unsuspend(ByVal Source As User, ByVal Channel As Channel)

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
Public Sub HandlePrefix(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Target As User)
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
        If (Not DB(DBIndexOf(Chan.Name)).LeaveOps) And bSet Then
            Select Case Char
                Case "v" 'Do we really care about this?
                Case "h"
                    If Target.IdentifiedToNick <> "" Then
                        If HasFlag(Chan.Name, Target.IdentifiedToNick, "-" & CHANSERV_HALFOP & CHANSERV_HALFOPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                            'Not a halfop, so bounce it.
                            '(Techinically, we should allow an op to keep halfops, but oh well :P .)
                            BotMode Chan, True, "-h", Target.Nick
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                            Exit Sub
                        End If
                    Else
                        'Not a halfop, so bounce it.
                        Chan.SendChannelModes "-h", Target.Nick
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                        Exit Sub
                    End If
                Case "o"
                    If Target.IdentifiedToNick <> "" Then
                        If HasFlag(Chan.Name, Target.IdentifiedToNick, "-" & CHANSERV_OP & CHANSERV_OPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                            'Not an op, so bounce it.
                            '(Techincally, we should allow admins and owners to keep it, but oh well :P .)
                            BotMode Chan, True, "-o", Target.Nick
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                            Exit Sub
                        End If
                    Else
                        'Not an op, so bounce it.
                        BotMode Chan, True, "-o", Target.Nick
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                        Exit Sub
                    End If
                Case "a"
                    If Target.IdentifiedToNick <> "" Then
                        If HasFlag(Chan.Name, Target.IdentifiedToNick, "-" & CHANSERV_PROTECT & CHANSERV_PROTECTOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                            'Not a protected user, so bounce it.
                            '(Techinically, we should allow an owner to keep admin, but oh well :P .)
                            BotMode Chan, True, "-a", Target.Nick
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                            Exit Sub
                        End If
                    Else
                        'Not a protected user, so bounce it.
                        BotMode Chan, True, "-a", Target.Nick
                        Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                        Exit Sub
                    End If
                Case "q"
                    If Target.IdentifiedToNick <> "" Then
                        If HasFlag(Chan.Name, Target.IdentifiedToNick, "-" & CHANSERV_OWNER & CHANSERV_OWNEROP & CHANSERV_PERMFOUNDER) Then
                            'Not an owner, so bounce it.
                            BotMode Chan, True, "-q", Target.Nick
                            Call basFunctions.SendMessage(Service(SVSINDEX_CHANSERV).Nick, Target.Nick, Replies.ChanServRegisteredChannel)
                            Exit Sub
                        End If
                    Else
                        'Not an owner, so bounce it.
                        BotMode Chan, True, "-q", Target.Nick
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
                    If DB(DBIndexOf(Chan.Name)).StrictStatus And Source = Target.Nick And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_VOICE & CHANSERV_VOICEOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-v", Target.Nick
                    ElseIf DB(DBIndexOf(Chan.Name)).StrictStatus And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_VOICEOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-v", Target.Nick
                    ElseIf (DB(DBIndexOf(Chan.Name)).SecureVoices And ACLIndexOf(DBIndexOf(Chan.Name), Target.IdentifiedToNick) < 0) Or HasAnyFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_QUIET & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER, "+" & CHANSERV_SUPERQUIET & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-v", Target.Nick
                    End If
                Case "h"
                    'Bounce if:
                    'Target is +D
                    'secure_halfops and user isn't on the ACL.
                    'strict_status and source doesn't have +H.
                    If DB(DBIndexOf(Chan.Name)).StrictStatus And Source = Target.Nick And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_HALFOP & CHANSERV_HALFOPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-h", Target.Nick
                    ElseIf DB(DBIndexOf(Chan.Name)).StrictStatus And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_HALFOPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-h", Target.Nick
                    ElseIf (DB(DBIndexOf(Chan.Name)).SecureHalfOps And ACLIndexOf(DBIndexOf(Chan.Name), Target.IdentifiedToNick) < 0) Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEHALFOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-h", Target.Nick
                    End If
                Case "o"
                    'Bounce if:
                    'Target is +d
                    'secure_ops and target isn't on the ACL.
                    'strict_status and source doesn't have +O.
                    If DB(DBIndexOf(Chan.Name)).StrictStatus And Source = Target.Nick And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OP & CHANSERV_OPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-o", Target.Nick
                    ElseIf DB(DBIndexOf(Chan.Name)).StrictStatus And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-o", Target.Nick
                    ElseIf (DB(DBIndexOf(Chan.Name)).SecureOps And ACLIndexOf(DBIndexOf(Chan.Name), Target.IdentifiedToNick) < 0) Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-o", Target.Nick
                    End If
                Case "a"
                    'Bounce if:
                    'Target is +d
                    'secure_ops and target isn't on the ACL.
                    'strict_status and source doesn't have +P.
                    If DB(DBIndexOf(Chan.Name)).StrictStatus And Source = Target.Nick And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_PROTECT & CHANSERV_PROTECTOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-a", Target.Nick
                    ElseIf DB(DBIndexOf(Chan.Name)).StrictStatus And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_PROTECTOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-a", Target.Nick
                    ElseIf (DB(DBIndexOf(Chan.Name)).SecureOps And ACLIndexOf(DBIndexOf(Chan.Name), Target.IdentifiedToNick) < 0) Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-a", Target.Nick
                    End If
                Case "q"
                    'Bounce if:
                    'Target is +d
                    'secure_ops and target isn't on the ACL.
                    'strict_status and source doesn't have +N.
                    If DB(DBIndexOf(Chan.Name)).StrictStatus And Source = Target.Nick And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OWNER & CHANSERV_OWNEROP & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-q", Target.Nick
                    ElseIf DB(DBIndexOf(Chan.Name)).StrictStatus And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OWNEROP & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-q", Target.Nick
                    ElseIf (DB(DBIndexOf(Chan.Name)).SecureOps And ACLIndexOf(DBIndexOf(Chan.Name), Target.IdentifiedToNick) < 0) Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "-q", Target.Nick
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
                    If Target.Nick <> Source And DB(DBIndexOf(Chan.Name)).StrictStatus And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_VOICEOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        'Bounce.
                        BotMode Chan, True, "+v", Target.Nick
                    ElseIf AccessLevel(Chan.Name, uSender.IdentifiedToNick) < AccessLevel(Chan.Name, Target.IdentifiedToNick) Then
                        'Just bounce it for now.
                        BotMode Chan, True, "+v", Target.Nick
                    End If
                Case "h"
                    'Bounce if:
                    'strict_status and source doesn't have +H.
                    'Target is of a higher level.
                    If Target.Nick <> Source And DB(DBIndexOf(Chan.Name)).StrictStatus And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_HALFOPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        BotMode Chan, True, "+h", Target.Nick
                    ElseIf AccessLevel(Chan.Name, uSender.IdentifiedToNick) < AccessLevel(Chan.Name, Target.IdentifiedToNick) Then
                        BotMode Chan, True, "+h", Target.Nick
                    End If
                Case "o"
                    'Bounce if:
                    'strict_status and source doesn't have +O.
                    'Target is of a higher level.
                    'Note: we can't pick service bot deops here. We'll have to use the MODE command
                    'callback for that.
                    If Target.Nick <> Source And DB(DBIndexOf(Chan.Name)).StrictStatus And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OPOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        BotMode Chan, True, "+o", Target.Nick
                    ElseIf AccessLevel(Chan.Name, uSender.IdentifiedToNick) < AccessLevel(Chan.Name, Target.IdentifiedToNick) Then
                        BotMode Chan, True, "+o", Target.Nick
                    End If
                Case "a"
                    'Bounce if:
                    'strict_status and source doesn't have +A.
                    'Target is of a higher level.
                    'Note: we can't pick service bot deops here. We'll have to use the MODE command
                    'callback for that.
                    If Target.Nick <> Source And DB(DBIndexOf(Chan.Name)).StrictStatus And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_PROTECTOP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        BotMode Chan, True, "+a", Target.Nick
                    ElseIf AccessLevel(Chan.Name, uSender.IdentifiedToNick) < AccessLevel(Chan.Name, Target.IdentifiedToNick) Then
                        BotMode Chan, True, "+a", Target.Nick
                    End If
                Case "q"
                    'Bounce if:
                    'strict_status and source doesn't have +N.
                    'Target is of a higher level.
                    'Note: we can't pick service bot deops here. We'll have to use the MODE command
                    'callback for that.
                    If Target.Nick <> Source And DB(DBIndexOf(Chan.Name)).StrictStatus And HasFlag(Chan.Name, uSender.IdentifiedToNick, "-" & CHANSERV_OWNEROP & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        BotMode Chan, True, "+q", Target.Nick
                    ElseIf AccessLevel(Chan.Name, uSender.IdentifiedToNick) < AccessLevel(Chan.Name, Target.IdentifiedToNick) Then
                        BotMode Chan, True, "+q", Target.Nick
                    End If
                'End Case
            End Select
        End If
    Else
        'Unknown user or server mode. Do only target access checks here.
        If bSet Then
            Select Case Char
                Case "v"
                    If (DB(DBIndexOf(Chan.Name)).SecureVoices And ACLIndexOf(DBIndexOf(Chan.Name), Target.IdentifiedToNick) < 0) Or HasAnyFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_QUIET & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER, "+" & CHANSERV_SUPERQUIET & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        BotMode Chan, True, "-v", Target.Nick
                    End If
                Case "h"
                    If (DB(DBIndexOf(Chan.Name)).SecureHalfOps And ACLIndexOf(DBIndexOf(Chan.Name), Target.IdentifiedToNick) < 0) Or HasAnyFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEHALFOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        BotMode Chan, True, "-h", Target.Nick
                    End If
                Case "o"
                    If (DB(DBIndexOf(Chan.Name)).SecureOps And ACLIndexOf(DBIndexOf(Chan.Name), Target.IdentifiedToNick) < 0) Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        BotMode Chan, True, "-o", Target.Nick
                    End If
                Case "a"
                    If (DB(DBIndexOf(Chan.Name)).SecureOps And ACLIndexOf(DBIndexOf(Chan.Name), Target.IdentifiedToNick) < 0) Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        BotMode Chan, True, "-a", Target.Nick
                    End If
                Case "q"
                    If (DB(DBIndexOf(Chan.Name)).SecureOps And ACLIndexOf(DBIndexOf(Chan.Name), Target.IdentifiedToNick) < 0) Or HasFlag(Chan.Name, Target.IdentifiedToNick, "+" & CHANSERV_DEOP & "-" & CHANSERV_COFOUNDER & CHANSERV_PERMFOUNDER) Then
                        BotMode Chan, True, "-q", Target.Nick
                    End If
                'End Case
            End Select
        Else
            'Not sure what to do here.
        End If
    End If
End Sub

Public Sub HandleModeTypeA(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)

End Sub

Public Sub HandleModeTypeB(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, ByVal Entry As String)
    DoMLOCK Chan, False
End Sub

Public Sub HandleModeTypeC(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String, Optional ByVal Entry As String)
    DoMLOCK Chan, False
End Sub

Public Sub HandleModeTypeD(ByVal Source As String, ByVal Chan As Channel, ByVal bSet As Boolean, ByVal Char As String)
    DoMLOCK Chan, False
End Sub

Public Sub HandleCommand(ByVal Sender As String, ByVal Cmd As String, ByRef Args() As String)

End Sub

Public Sub HandleUserMode(ByVal User As User, ByVal bSet As Boolean, ByVal Char As String)

End Sub

Public Sub HandleTick(ByVal Interval As Single)
    Dim c As Channel, sng As Single
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
    Dim chptr As Channel, sptr As User, dbch As Long
    Dim akidx As Long, aceptr As Long
    Select Case EventName
        Case basEvents.ChanCreate
            Set chptr = Parameters(0)
            Set sptr = Parameters(1)
            dbch = DBIndexOf(chptr.Name)
            If dbch < 0 Then Exit Sub
            aceptr = ACLIndexOf(dbch, sptr.Nick)
            akidx = GetFirstAKick(chptr.Name, sptr)
            If GetFirstExempt(chptr.Name, sptr) >= 0 Or HasAnyFlagIdx(dbch, aceptr, CHANSERV_EXEMPT, CHANSERV_EXEMPTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then akidx = -1
            If akidx >= 0 Then
                'Creator is autokicked, so boot him out.
                chptr.Custom.Add True, "NoFullTerm"
                With DB(DBIndexOf(dbch)).AKicks(akidx)
                    chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+b", .Mask
                    chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replace(Replace(IIf(.Expiry > 0, Replies.ChanServAKICKTemp, Replies.ChanServAKICKPerm), "%c", chptr.Name), "%r", .Reason)
                    basFunctions.SendNumeric sptr.Nick, 474, chptr.Name & " :Cannot join channel (+b)"
                End With
            ElseIf HasFlagIdx(dbch, aceptr, "+" + CHANSERV_AUTOKICK + "-" + CHANSERV_COFOUNDER + CHANSERV_PERMFOUNDER) Then
                chptr.Custom.Add True, "NoFullTerm"
                chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+b", "*!*@" + IIf(Len(sptr.VirtHost) > 0, sptr.VirtHost, sptr.HostName)
                chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replies.ChanServKickNoJoin
                basFunctions.SendNumeric sptr.Nick, 474, chptr.Name & " :Cannot join channel (+b)"
            'Is the channel restricted, and the user not on the ACL (thus effectively +K'd)?
            ElseIf DB(dbch).Restricted And aceptr < 0 Then
                chptr.Custom.Add True, "NoFullTerm"
                chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+b", "*!*@" + IIf(Len(sptr.VirtHost) > 0, sptr.VirtHost, sptr.HostName)
                chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replies.ChanServKickNoJoin
                basFunctions.SendNumeric sptr.Nick, 473, chptr.Name & " :Cannot join channel (+i)"
            'Is the channel +A, +O, or +z, and the user is not?
            ElseIf (InStr(chptr.Modes, "A") > 0 And InStr(sptr.Modes, "A") = 0) Then
                chptr.Custom.Add True, "NoFullTerm"
                chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+b", "*!*@" + IIf(Len(sptr.VirtHost) > 0, sptr.VirtHost, sptr.HostName)
                chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replies.ChanServKickNoJoin
                basFunctions.SendNumeric sptr.Nick, 519, chptr.Name & " :Cannot join channel (Admins Only)"
            ElseIf (InStr(chptr.Modes, "O") > 0 And InStr(sptr.Modes, "o") = 0) Then
                chptr.Custom.Add True, "NoFullTerm"
                chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+b", "*!*@" + IIf(Len(sptr.VirtHost) > 0, sptr.VirtHost, sptr.HostName)
                chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replies.ChanServKickNoJoin
                basFunctions.SendNumeric sptr.Nick, 520, chptr.Name & " :Cannot join channel (IRCops Only)"
            ElseIf (InStr(chptr.Modes, "z") > 0 And InStr(sptr.Modes, "z") = 0) Then
                chptr.Custom.Add True, "NoFullTerm"
                chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+b", "*!*@" + IIf(Len(sptr.VirtHost) > 0, sptr.VirtHost, sptr.HostName)
                chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replies.ChanServKickNoJoin
                basFunctions.SendNumeric sptr.Nick, 489, chptr.Name & " :Cannot join channel (+z)"
            Else
                'Otherwise, initialize the channel.
                Call basFunctions.Notice(Service(SVSINDEX_CHANSERV).Nick, chptr.Name, "This channel is operated by " + Service(SVSINDEX_CHANSERV).Nick + ".")
                InitChannel chptr
                InitChUser chptr, sptr
            End If
        Case basEvents.ChanJoin
            Set chptr = Parameters(0)
            Set sptr = Parameters(1)
            dbch = DBIndexOf(chptr.Name)
            If dbch < 0 Then Exit Sub
            aceptr = ACLIndexOf(dbch, sptr.Nick)
            akidx = GetFirstAKick(chptr.Name, sptr)
            If GetFirstExempt(chptr.Name, sptr) >= 0 Or HasAnyFlagIdx(dbch, aceptr, CHANSERV_EXEMPT, CHANSERV_EXEMPTOP, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Then akidx = -1
            If akidx >= 0 Then
                'Joiner is autokicked, so boot him out.
                With DB(DBIndexOf(dbch)).AKicks(akidx)
                    chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+b", .Mask
                    chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replace(Replace(IIf(.Expiry > 0, Replies.ChanServAKICKTemp, Replies.ChanServAKICKPerm), "%c", chptr.Name), "%r", .Reason)
                    basFunctions.SendNumeric sptr.Nick, 474, chptr.Name & " :Cannot join channel (+b)"
                End With
            ElseIf HasFlagIdx(dbch, aceptr, "+" + CHANSERV_AUTOKICK + "-" + CHANSERV_COFOUNDER + CHANSERV_PERMFOUNDER) Then
                chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+b", "*!*@" + IIf(Len(sptr.VirtHost) > 0, sptr.VirtHost, sptr.HostName)
                chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replies.ChanServKickNoJoin
                basFunctions.SendNumeric sptr.Nick, 474, chptr.Name & " :Cannot join channel (+b)"
            'Is the channel restricted, and the user not on the ACL (thus effectively +K'd)?
            ElseIf DB(dbch).Restricted And aceptr < 0 Then
                chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+b", "*!*@" + IIf(Len(sptr.VirtHost) > 0, sptr.VirtHost, sptr.HostName)
                chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replies.ChanServKickNoJoin
                basFunctions.SendNumeric sptr.Nick, 473, chptr.Name & " :Cannot join channel (+i)"
            'Is the channel +A, +O, or +z, and the user is not?
            ElseIf (InStr(chptr.Modes, "A") > 0 And InStr(sptr.Modes, "A") = 0) Then
                chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+Ab", "*!*@" + IIf(Len(sptr.VirtHost) > 0, sptr.VirtHost, sptr.HostName)
                chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replies.ChanServKickNoJoin
                basFunctions.SendNumeric sptr.Nick, 519, chptr.Name & " :Cannot join channel (Admins Only)"
            ElseIf (InStr(chptr.Modes, "O") > 0 And InStr(sptr.Modes, "o") = 0) Then
                chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+Ob", "*!*@" + IIf(Len(sptr.VirtHost) > 0, sptr.VirtHost, sptr.HostName)
                chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replies.ChanServKickNoJoin
                basFunctions.SendNumeric sptr.Nick, 520, chptr.Name & " :Cannot join channel (IRCops Only)"
            ElseIf (InStr(chptr.Modes, "z") > 0 And InStr(sptr.Modes, "z") = 0) Then
                chptr.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "+zb", "*!*@" + IIf(Len(sptr.VirtHost) > 0, sptr.VirtHost, sptr.HostName)
                chptr.KickUser Service(SVSINDEX_CHANSERV).Nick, sptr, Replies.ChanServKickNoJoin
                basFunctions.SendNumeric sptr.Nick, 489, chptr.Name & " :Cannot join channel (+z)"
            Else
                'Otherwise, do our stuff for this user.
                InitChUser chptr, sptr
            End If
        Case basEvents.ChanDestroy
            Set chptr = Parameters(0)
            Set sptr = Parameters(1)
            On Error Resume Next
            Dim b As Boolean: b = chptr.Custom("NoFullTerm")
            If Not b Then TermChannel chptr
        Case basEvents.ServiceChanModeChanged
            Set chptr = Parameters(0)
            Dim src As String, ch As String, sNick As String
            src = Parameters(1)
            ch = Parameters(2)
            sNick = Parameters(3)
            If Not IsServicesNick(sNick) Then Exit Sub
            If IsServicesNick(src) Or src = basMain.Config.ServerName Then Exit Sub
            'In all cases, we want our bot to be at least +ao.
            If ch = "-a" Then chptr.SendChannelModes basMain.Config.ServerName, "+a", sNick
            If ch = "-o" Then chptr.SendChannelModes basMain.Config.ServerName, "+o", sNick
    End Select
End Sub

'Some general subs.
Public Sub InitChannel(ByVal Channel As Channel)
    Dim s As String
    Dim vBots() As String
    vBots = DB(DBIndexOf(Channel.Name)).Bots
    'The first character will be the prefix, so...
    Dim v As Variant
    For Each v In vBots
        If Len(v) > 0 Then
            Call JoinBot(Channel, Mid(v, 2))
        End If
    Next v
    DoMLOCK Channel, True
    BotTopic Channel, DB(DBIndexOf(Channel.Name)).LastTopic, DB(DBIndexOf(Channel.Name)).TopicSetBy, DB(DBIndexOf(Channel.Name)).TopicSetOn
End Sub

Public Sub InitChUser(ByVal Channel As Channel, ByVal User As User)
    Dim chptr As Long, cptr As Long
    chptr = DBIndexOf(Channel.Name)
    cptr = ACLIndexOf(chptr, User.IdentifiedToNick)
    If HasAnyFlagIdx(chptr, cptr, CHANSERV_SHOWGREET, CHANSERV_COFOUNDER, CHANSERV_PERMFOUNDER) Or Channel.IdentifedUsers.Exists(User) Then
        'Show the greet message.
    End If
    If DB(chptr).Give Then
        If HasAnyFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER) Then
            'Set +qo.
            BotMode Channel, True, "+qo" + User.Nick + " " + User.Nick
        ElseIf HasAnyFlagIdx(chptr, cptr, CHANSERV_COFOUNDER) Or Channel.IdentifedUsers.Exists(User) Then
            If HasAnyFlagIdx(chptr, cptr, CHANSERV_OWNER, CHANSERV_OWNEROP) Then
                'Set +qo.
                BotMode Channel, True, "+qo", User.Nick, User.Nick
            Else
                'Set +ao.
                BotMode Channel, True, "+ao", User.Nick, User.Nick
            End If
        ElseIf HasAnyFlagIdx(chptr, cptr, CHANSERV_OWNER, CHANSERV_OWNEROP) Then
            If HasAnyFlagIdx(chptr, cptr, CHANSERV_OP, CHANSERV_OPOP) Then
                'Set +qo.
                BotMode Channel, True, "+qo", User.Nick, User.Nick
            ElseIf HasAnyFlagIdx(chptr, cptr, CHANSERV_HALFOP, CHANSERV_HALFOPOP) Then
                'Set +qh.
                BotMode Channel, True, "+qh", User.Nick, User.Nick
            ElseIf HasAnyFlagIdx(chptr, cptr, CHANSERV_VOICE, CHANSERV_VOICEOP) Then
                'Set +qv.
                BotMode Channel, True, "+qv", User.Nick, User.Nick
            Else
                'Set +q.
                BotMode Channel, True, "+q", User.Nick
            End If
        ElseIf HasAnyFlagIdx(chptr, cptr, CHANSERV_PROTECT, CHANSERV_PROTECTOP) Then
            If HasAnyFlagIdx(chptr, cptr, CHANSERV_OP, CHANSERV_OPOP) Then
                'Set +ao.
                BotMode Channel, True, "+ao", User.Nick, User.Nick
            ElseIf HasAnyFlagIdx(chptr, cptr, CHANSERV_HALFOP, CHANSERV_HALFOPOP) Then
                'Set +ah.
                BotMode Channel, True, "+ah", User.Nick, User.Nick
            ElseIf HasAnyFlagIdx(chptr, cptr, CHANSERV_VOICE, CHANSERV_VOICEOP) Then
                'Set +av.
                BotMode Channel, True, "+av", User.Nick, User.Nick
            Else
                'Set +a.
                BotMode Channel, True, "+a", User.Nick
            End If
        ElseIf HasAnyFlagIdx(chptr, cptr, CHANSERV_OP, CHANSERV_OPOP) Then
            'Set +o.
            BotMode Channel, True, "+o", User.Nick
        ElseIf HasAnyFlagIdx(chptr, cptr, CHANSERV_HALFOP, CHANSERV_HALFOPOP) Then
            'Set +h.
            BotMode Channel, True, "+h", User.Nick
        ElseIf HasAnyFlagIdx(chptr, cptr, CHANSERV_VOICE, CHANSERV_VOICEOP) Then
            'Set +v.
            BotMode Channel, True, "+v", User.Nick
        End If
    End If
End Sub

Public Sub TermChannel(ByVal Channel As Channel)
    Dim vBots() As String
    vBots = DB(DBIndexOf(Channel.Name)).Bots
    'The first character will be the prefix, so...
    Dim v As Variant
    For Each v In vBots
        If Len(v) > 0 Then
            SendData FormatString(":{0} PART {1}", Mid(v, 2), Channel.Name)
        End If
    Next v
End Sub

'Enforces the MLOCK of the given channel.
Public Sub DoMLOCK(ByVal Channel As Channel, Optional ByVal UpdateFloatingLimit As Boolean = False)
    Dim MLock As String
    On Error Resume Next
    MLock = DB(DBIndexOf(Channel.Name)).MLock
    If Err.Number <> 0 Then 'Not registered, so the mlock is -r and nothing more.
        If InStr(1, Channel.Modes, "r", vbBinaryCompare) Then
            Channel.SendChannelModes Service(SVSINDEX_CHANSERV).Nick, "-r"
        End If
        Exit Sub
    End If
    'Now parse the mlock.
    'The mlock is formatted as <binaryflags> [[<paramflags> <params>]]
    Dim m() As String
    m = Split(MLock, " ")
    Dim bSet As Boolean
    Dim sSet As String, sUnSet As String 'Modes we can send w/o a parameter.
    Dim idx As Long, ch As String * 1
    sSet = IIf(InStr(Channel.Modes, "r") > 0, "", "r")
    sUnSet = ""
    For idx = 1 To Len(m(0))
        ch = Mid(m(0), idx, 1)
        If ch = "+" Then
            bSet = True
        ElseIf ch = "-" Then
            bSet = False
        ElseIf ch = "r" Then 'Ignore it.
        ElseIf bSet And ch = "l" And UpdateFloatingLimit Then
            BotMode Channel, True, "+l " & CStr(Channel.Members.Count + 8)
        ElseIf Not bSet And InStr(1, Split(basMain.ChannelModes2, ",", 2)(1), ch, vbBinaryCompare) Then
            '- and a Type B, C, or D mode.
            If ch = "f" And Channel.FloodProtection <> "" Then
                BotMode Channel, True, "-f " & Channel.FloodProtection
            ElseIf ch = "k" And Channel.ChannelKey <> "" Then
                BotMode Channel, True, "-k " & Channel.ChannelKey
            ElseIf ch = "L" And Channel.OverflowChannel <> "" Then
                BotMode Channel, True, "-L " & Channel.OverflowChannel
            ElseIf ch = "l" And Channel.OverflowLimit <> 0 Then
                sUnSet = sUnSet & "l"
            ElseIf InStr(1, Channel.Modes, ch, vbBinaryCompare) Then
                sUnSet = sUnSet & ch
            End If
        ElseIf bSet And InStr(1, Split(basMain.ChannelModes2, ",")(3), ch, vbBinaryCompare) Then
            '+ and a Type D mode.
            If InStr(1, Channel.Modes, ch, vbBinaryCompare) = 0 Then
                sSet = sSet & ch
            End If
        End If
    Next idx
    BotMode Channel, True, "+" & sSet & "-" & sUnSet
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
                            If Channel.OverflowLimit <> CLng(sParam) Then
                                BotMode Channel, True, "+l " & sParam
                            End If
                        End If
                    Case "k":
                        If Channel.ChannelKey <> sParam Then
                            BotMode Channel, True, "+k " & sParam
                        End If
                    Case "L":
                        If Channel.OverflowChannel <> sParam Then
                            BotMode Channel, True, "+L " & sParam
                        End If
                    Case "f":
                        If Channel.FloodProtection <> sParam Then
                            BotMode Channel, True, "+f " & sParam
                        End If
                    Case Else
                        'We can't optimize it down, so just send the dang thing already.
                        BotMode Channel, True, FormatString("+{0} {1}", ch, sParam)
                    'End Case
                End Select
            End If
        Next idx2
    Next idx
End Sub

Public Sub JoinBot(ByVal Channel As Channel, ByVal Bot As String)
    If LCase(basMain.Config.ServerType = "UNREAL") Then
        'This is a bit misleading, but oh well:
        '* = Owner, ~ = Admin, @ = Op, % = Voice, + = Voice
        Call basFunctions.SendData(FormatString("SJOIN {0} {1} :*@{2}", DB(DBIndexOf(Channel)).TimeRegistered, Channel.Name, Bot))
    Else
        Call basFunctions.SendData(":" + Bot & " JOIN " & Channel.Name)
        Call basFunctions.SendData(":" + Bot & " MODE " & Channel.Name & " +ao " & Bot & " " & Bot)
    End If
End Sub

Public Sub BotKick(ByVal Channel As Channel, ByVal Auto As Boolean, ByVal Target As User, ByVal Reason As String)
    Dim vBot As String
    vBot = IIf(Auto, DB(DBIndexOf(Channel.Name)).BotAutoKick, DB(DBIndexOf(Channel.Name)).BotKick)
    If vBot = "" Then vBot = Service(SVSINDEX_CHANSERV).Nick
    Channel.KickUser vBot, Target, Reason
End Sub

Public Sub BotMode(ByVal Channel As Channel, ByVal Auto As Boolean, ByVal Modes As String, ParamArray Args() As Variant)
    Dim vBot As String
    vBot = IIf(Auto, DB(DBIndexOf(Channel.Name)).BotAutoMode, DB(DBIndexOf(Channel.Name)).BotMode)
    If vBot = "" Then vBot = Service(SVSINDEX_CHANSERV).Nick
    Channel.SendChannelModes vBot, Modes, Args
End Sub

Public Sub BotTopic(ByVal Channel As Channel, ByVal Topic As String, ByVal SetBy As String, ByVal SetOn As Long)
    Dim vBot As String
    vBot = DB(DBIndexOf(Channel.Name)).BotTopic
    If vBot = "" Then vBot = Service(SVSINDEX_CHANSERV).Nick
    Channel.Topic = Topic
    Channel.TopicSetBy = SetBy
    Channel.TopicSetOn = SetOn
    Call basFunctions.SendData(FormatString(":{0} TOPIC {1} {2} {3} :{4}", vBot, Channel.Name, SetBy, SetOn, Topic))
End Sub

'A slightly more efficient version of HasFlag when the caller already has the indexes...
Public Function HasFlagIdx(ByVal chptr As Long, ByVal cptr As Long, ByVal Flag As String) As Boolean
    Dim Flags As String
    If cptr = 0 Then
        Flags = ""
    Else
        Flags = DB(chptr).AccessList(cptr).Flags
    End If
    Dim idx As Long, bSet As Boolean
    For idx = 1 To Len(Flag)
        Select Case Mid(Flag, idx, 1)
            Case "+": bSet = True
            Case "-": bSet = False
            Case Else:
                If (bSet And InStr(Flags, Mid(Flag, idx, 1)) = 0) Or (Not bSet And InStr(Flags, Mid(Flag, idx, 1)) > 0) Then
                    HasFlagIdx = False
                    Exit Function
                End If
            'End Case
        End Select
    Next idx
    HasFlagIdx = True
End Function

Public Function HasFlag(ByVal Channel As String, ByVal User As String, ByVal Flag As String) As Boolean
    Dim Flags As String, chptr As Long, cptr As Long
    chptr = DBIndexOf(Channel)
    cptr = ACLIndexOf(chptr, User)
    HasFlag = HasFlagIdx(chptr, cptr, Flag)
End Function

Public Function HasFlagInsecureIdx(ByVal chptr As Long, ByVal sptrNick As Long, ByVal sptrIdentified As Long, ByVal Flag As String) As Boolean
    If DB(chptr).Secure Then
        HasFlagInsecureIdx = HasFlagIdx(chptr, sptrIdentified, Flag)
    Else
        HasFlagInsecureIdx = HasFlagIdx(chptr, sptrNick, Flag) Or HasFlagIdx(chptr, sptrIdentified, Flag)
    End If
End Function

Public Function HasFlagInsecure(ByVal Chan As String, ByVal Nick As String, ByVal account As String, ByVal Flag As String) As Boolean
    Dim chptr As Long
    chptr = DBIndexOf(Chan)
    HasFlagInsecure = HasFlagInsecureIdx(chptr, ACLIndexOf(chptr, Nick), ACLIndexOf(chptr, account), Flag)
End Function

Public Function HasAnyFlagIdx(ByVal chptr As Long, ByVal cptr As Long, ParamArray Flags() As Variant) As Boolean
    Dim idx As Long
    For idx = LBound(Flags) To UBound(Flags)
        If Not IsMissing(Flags(idx)) Then
            If HasFlagIdx(chptr, cptr, Flags(idx)) Then
                HasAnyFlagIdx = True
                Exit Function
            End If
        End If
    Next idx
    HasAnyFlagIdx = False
End Function

Public Function HasAnyFlag(ByVal Channel As String, ByVal User As String, ParamArray Flags() As Variant) As Boolean
    Dim idx As Long, chptr As Long, cptr As Long
    chptr = DBIndexOf(Channel)
    cptr = ACLIndexOf(chptr, User)
    HasAnyFlag = HasAnyFlagIdx(chptr, cptr, Flags)
End Function

Public Sub SetFlag(ByVal Channel As String, ByVal User As String, ByVal Flag As String)
    Dim Flags As String
    Dim chptr As Long, cptr As Long
    chptr = DBIndexOf(Channel)
    cptr = ACLIndexOf(chptr, User)
    If cptr >= 0 Then
        Flags = DB(chptr).AccessList(cptr).Flags
    Else
        Flags = ""
    End If
    Dim idx As Long, bSet As Boolean
    For idx = 1 To Len(Flag)
        Select Case Mid(Flag, idx, 1)
            Case "+": bSet = True
            Case "-": bSet = False
            Case Else:
                If (bSet And InStr(Flags, Mid(Flag, idx, 1)) = 0) Then
                    Flags = Flags & Mid(Flag, idx, 1)
                ElseIf (Not bSet And InStr(Flags, Mid(Flag, idx, 1)) > 0) Then
                    Flags = Replace(Flags, Mid(Flag, idx, 1), "")
                End If
            'End Case
        End Select
    Next idx
    If cptr >= 0 Then
        DB(chptr).AccessList(cptr).Flags = Flags
    Else
        ReDim Preserve DB(chptr).AccessList(UBound(DB(chptr).AccessList) + 1)
        With DB(chptr).AccessList(UBound(DB(chptr).AccessList))
            .Nick = User
            .Flags = Flags
            .Lock = LOCK_LOCK
        End With
    End If
End Sub

Public Function GetFirstAKick(ByVal Channel As String, ByVal User As User) As Long
    Dim idx As Long, chptr As Long
    chptr = DBIndexOf(Channel)
    For idx = 0 To UBound(DB(chptr).AKicks)
        With DB(chptr).AKicks(idx)
            If NUHMaskIsMatch(User, .Mask) Then
                GetFirstAKick = idx
                Exit Function
            End If
        End With
    Next idx
    GetFirstAKick = -1
End Function

Public Function GetFirstExempt(ByVal Channel As String, ByVal User As User) As Long
    Dim idx As Long, chptr As Long
    chptr = DBIndexOf(Channel)
    For idx = 0 To UBound(DB(chptr).Exempts)
        With DB(chptr).Exempts(idx)
            If NUHMaskIsMatch(User, .Mask) Then
                GetFirstExempt = idx
                Exit Function
            End If
        End With
    Next idx
    GetFirstExempt = -1
End Function

Public Function GetFirstInvite(ByVal Channel As String, ByVal User As User) As Long
    Dim idx As Long, chptr As Long
    chptr = DBIndexOf(Channel)
    For idx = 0 To UBound(DB(chptr).Invites)
        With DB(chptr).Invites(idx)
            If NUHMaskIsMatch(User, .Mask) Then
                GetFirstInvite = idx
                Exit Function
            End If
        End With
    Next idx
    GetFirstInvite = -1
End Function

Public Function AccessLevelIdx(ByVal chptr As Long, ByVal cptr As Long) As Integer
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
    If HasFlagIdx(chptr, cptr, CHANSERV_PERMFOUNDER) Then
        AccessLevelIdx = 12
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_COFOUNDER) Then
        AccessLevelIdx = 11
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_OWNEROP) Then
        AccessLevelIdx = 10
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_OWNER) Then
        AccessLevelIdx = 9
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_PROTECTOP) Then
        AccessLevelIdx = 8
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_PROTECT) Then
        AccessLevelIdx = 7
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_OPOP) Then
        AccessLevelIdx = 6
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_OP) Then
        AccessLevelIdx = 5
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_HALFOPOP) Then
        AccessLevelIdx = 4
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_HALFOP) Then
        AccessLevelIdx = 3
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_VOICEOP) Then
        AccessLevelIdx = 2
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_VOICE) Then
        AccessLevelIdx = 1
    ElseIf HasFlagIdx(chptr, cptr, CHANSERV_AUTOKICK) Then
        AccessLevelIdx = -1
    Else
        AccessLevelIdx = 0
    End If
End Function

Public Function AccessLevel(ByVal Channel As String, ByVal User As String) As Integer
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
    If HasFlag(Channel, User, CHANSERV_PERMFOUNDER) Then
        AccessLevel = 12
    ElseIf HasFlag(Channel, User, CHANSERV_COFOUNDER) Then
        AccessLevel = 11
    ElseIf HasFlag(Channel, User, CHANSERV_OWNEROP) Then
        AccessLevel = 10
    ElseIf HasFlag(Channel, User, CHANSERV_OWNER) Then
        AccessLevel = 9
    ElseIf HasFlag(Channel, User, CHANSERV_PROTECTOP) Then
        AccessLevel = 8
    ElseIf HasFlag(Channel, User, CHANSERV_PROTECT) Then
        AccessLevel = 7
    ElseIf HasFlag(Channel, User, CHANSERV_OPOP) Then
        AccessLevel = 6
    ElseIf HasFlag(Channel, User, CHANSERV_OP) Then
        AccessLevel = 5
    ElseIf HasFlag(Channel, User, CHANSERV_HALFOPOP) Then
        AccessLevel = 4
    ElseIf HasFlag(Channel, User, CHANSERV_HALFOP) Then
        AccessLevel = 3
    ElseIf HasFlag(Channel, User, CHANSERV_VOICEOP) Then
        AccessLevel = 2
    ElseIf HasFlag(Channel, User, CHANSERV_VOICE) Then
        AccessLevel = 1
    ElseIf HasFlag(Channel, User, CHANSERV_AUTOKICK) Then
        AccessLevel = -1
    Else
        AccessLevel = 0
    End If
End Function

Public Function DBIndexOf(ByVal Name As String) As Long
    Dim idx As Long
    On Local Error Resume Next
    idx = UBound(DB)
    If Err = 0 Then
        DBIndexOf = -1
        Exit Function
    End If
    On Error GoTo 0
    For idx = 0 To UBound(DB)
        If DB(idx).Name = Name Then
            DBIndexOf = idx
            Exit Function
        End If
    Next idx
    DBIndexOf = -1
End Function

Public Function ACLIndexOf(ByVal ChIdx As Long, ByVal User As String) As Long
    Dim idx As Long
    For idx = 0 To UBound(DB(ChIdx).AccessList)
        If DB(ChIdx).AccessList(idx).Nick = User Then
            ACLIndexOf = idx
            Exit Function
        End If
    Next idx
    ACLIndexOf = -1
End Function

Public Function AKickIndexOf(ByVal ChIdx As Long, ByVal Mask As String) As Long
    Dim idx As Long
    On Error GoTo NoAKicks
    For idx = 0 To UBound(DB(ChIdx).AKicks)
        If DB(ChIdx).AKicks(idx).Mask = Mask Then
            AKickIndexOf = idx
            Exit Function
        End If
    Next idx
NoAKicks:
    AKickIndexOf = -1
End Function

Public Sub AddAKick(ByVal ChIdx As Long, ByVal Mask As String, ByVal Reason As String, Optional ByVal Expiry As Long = 0)
    If AKickIndexOf(ChIdx, Mask) < 0 Then
        With DB(ChIdx)
            On Error GoTo InitAKicks
            ReDim Preserve .AKicks(UBound(.AKicks) + 1)
            With .AKicks(UBound(.AKicks))
                .Mask = Mask
                .Reason = Reason
                .Expiry = Expiry
            End With
        End With
    End If
    Exit Sub
InitAKicks:
    If Err.Number = 9 Then
        'UBound failed because the array is blank.
        ReDim DB(ChIdx).AKicks(0)
        Resume Next
    End If
End Sub

Public Sub DelAKick(ByVal ChIdx As Long, ByVal akidx As Long)
    Dim idx As Long
    With DB(ChIdx)
        If UBound(.AKicks) = 0 Then
            Erase .AKicks 'Deallocate the array.
        Else
            For idx = akidx + 1 To UBound(.AKicks)
                .AKicks(idx - 1) = .AKicks(idx)
            Next idx
            ReDim Preserve .AKicks(UBound(.AKicks) - 1)
        End If
    End With
End Sub

Public Function ExemptIndexOf(ByVal ChIdx As Long, ByVal Mask As String) As Long
    Dim idx As Long
    For idx = 0 To UBound(DB(ChIdx).Exempts)
        If DB(ChIdx).Exempts(idx).Mask = Mask Then
            ExemptIndexOf = idx
            Exit Function
        End If
    Next idx
    ExemptIndexOf = -1
End Function

Public Sub AddExempt(ByVal ChIdx As Long, ByVal Mask As String, Optional ByVal Expiry As Long = 0)
    If ExemptIndexOf(ChIdx, Mask) < 0 Then
        With DB(ChIdx)
            On Error GoTo InitExempts
            ReDim Preserve .Exempts(UBound(.Exempts) + 1)
            With .Exempts(UBound(.Exempts))
                .Mask = Mask
                .Expiry = Expiry
            End With
        End With
    End If
    Exit Sub
InitExempts:
    If Err.Number = 9 Then
        'UBound failed because the array is blank.
        ReDim DB(ChIdx).Exempts(0)
        Resume Next
    End If
End Sub

Public Sub DelExempt(ByVal ChIdx As Long, ByVal akidx As Long)
    Dim idx As Long
    With DB(ChIdx)
        If UBound(.Exempts) = 0 Then
            Erase .Exempts 'Deallocate the array.
        Else
            For idx = akidx + 1 To UBound(.Exempts)
                .Exempts(idx - 1) = .Exempts(idx)
            Next idx
            ReDim Preserve .Exempts(UBound(.Exempts) - 1)
        End If
    End With
End Sub

Public Function InviteIndexOf(ByVal ChIdx As Long, ByVal Mask As String) As Long
    Dim idx As Long
    For idx = 0 To UBound(DB(ChIdx).Invites)
        If DB(ChIdx).Invites(idx).Mask = Mask Then
            InviteIndexOf = idx
            Exit Function
        End If
    Next idx
    InviteIndexOf = -1
End Function

Public Sub AddInvite(ByVal ChIdx As Long, ByVal Mask As String, Optional ByVal Expiry As Long = 0)
    If InviteIndexOf(ChIdx, Mask) < 0 Then
        With DB(ChIdx)
            On Error GoTo InitInvites
            ReDim Preserve .Invites(UBound(.Invites) + 1)
            With .Invites(UBound(.Invites))
                .Mask = Mask
                .Expiry = Expiry
            End With
        End With
    End If
    Exit Sub
InitInvites:
    If Err.Number = 9 Then
        'UBound failed because the array is blank.
        ReDim DB(ChIdx).Invites(0)
        Resume Next
    End If
End Sub

Public Sub DelInvite(ByVal ChIdx As Long, ByVal akidx As Long)
    Dim idx As Long
    With DB(ChIdx)
        If UBound(.Invites) = 0 Then
            Erase .Invites 'Deallocate the array.
        Else
            For idx = akidx + 1 To UBound(.Invites)
                .Invites(idx - 1) = .Invites(idx)
            Next idx
            ReDim Preserve .Invites(UBound(.Invites) - 1)
        End If
    End With
End Sub

