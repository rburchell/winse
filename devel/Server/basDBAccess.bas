Attribute VB_Name = "basDBAccess"
Option Explicit

'This module deals with DataBase access.
'I know w00t wants to specifically use MySQL, but for
'now I'm going to just provide a basic interface:
'Binary data files. Nice thing is we don't have to mess
'with SQL, which I would probably need to learn anyway
':P. Later we can probably make a seperate module for
'MySQL access, but I want to finalize this stuff here
'before that's done.

'First, I'll start with the internal cache of the DB,
'which is stored inside the structs.
'Everything is going to be fixed length, so we'll use
'constants (again) to make things adjustable.

'Don't start moving to this engine just yet. I want to
'finalize the DB structures before we do that, so that
'we don't invalidate databases everytime there's an
'upgrade. I'm probably going to think of some way we
'CAN upgrade DBs and be backwards-compatible (and no,
'MySQL probably won't help there ;p)

Public Enum EnforceType
    ET_USEKILL = 1 'Use KILL instead of SVSNICK.
    ET_QUICK = 2   'Wait 20 seconds instead of 60.
    ET_IMMED = 4   'Enforce immediately.
End Enum

Public Type MemoRecord
    Sender As String
    Text As String
    TS As Long
End Type

'This will be the structure for the NickName database.

Public Type NickDBRecord 'NickServ Crap
    NickName As String
    Password As String
    EMail As String
    Info As String
    Access As Integer
    MsgStyle As String * 1
    AutoJoin() As String
    Enforce As Integer 'Use EnforceType Enum
    Secure As Boolean 'Not auto-id'd even on ACL match.
    Private As Boolean 'Not LISTed except to service ops.
    HideEMail As Boolean 'Hide registered E-Mail addr.
    HideLastAddr As Boolean 'Hide last user@host.
    HideLastQuit As Boolean 'Hide last QUIT reason.
    LastAddress As String 'Last seen address user@host
    LastRealName As String 'Last seen realname field.
    LastSeenTS As Long 'Time last signed on (could use for expiration too?)
    LastQuit As String 'Reason for last quit.
    ACL() As String 'user@host masks.
    Memos() As MemoRecord
End Type

Public Type ChannelDB_UserAccessRecord
    Nick As String
    Access As Integer
End Type

Public Type ChannelDBRecord 'ChanServ+BotServ Crap
    Channel As String
    Password As String
    Founder As String 'The nick name. Duh.
    Info As String
    Bot As String 'Nick of a BotServ bot?
    ACL() As ChannelDB_UserAccessRecord
    Memos() As MemoRecord
    Secure As Boolean 'ACL only works on IDENTIFY'd users?
    SecureVoice As Boolean 'Only allow +v for ACL folks?
    SecureOps As Boolean 'Only allow +hoaq for ACL folks?
     'Restrict some commands to the real founder.
     '-or- only allow +q for founder(s).
    SecureFounder As Boolean
     'Not LISTed except to service ops.
     'also, maybe MLOCK'd +p or +s?
    Private As Boolean
     'Suspended channel. (To mark a channel as forbidden
     'simply set this to True, and blank the Founder
     'field (and everything else while you're at it).)
    Suspended As Boolean
End Type

Public Type BotDBRecord 'BotServ Crap
    BotNick As String
    BotUser As String
    BotHost As String
    BotInfo As String
    Private As Boolean 'Bot only usable by IRCops.
End Type

Public Enum BanType
    BT_AKILL = 1 'user@host
    BT_NLINE = 2 'real name
    BT_ZLINE = 3 'ip address
    BT_QLINE = 4 'nickname
    BT_JUPE = 5  'Jupe'd server. (No wildcarding?)
End Enum

Public Type BanDBRecord
    Type As Integer 'Use BanType
    Mask As String
    Reason As String
    Expire As Long 'TS for expiration, 0 for never.
End Type

Public Type Database
    Nicks() As NickDBRecord
    Chans() As ChannelDBRecord
    Bots() As BotDBRecord
    Bans() As BanDBRecord
End Type

Public Sub LoadDatabase(ByVal File As String, ByRef db As Database)
    'See if it exists.
    If Dir(File) = "" Then
        Error 53 'File not found
    End If
    Dim fd As Integer
    fd = FreeFile
    'Request Binary read access, and block write access
    'to other programs.
    Open File For Binary Access Read Lock Write As #fd
    Get #fd, 1, db
    Close #fd
End Sub

Public Sub SaveDatabase(ByVal File As String, ByRef db As Database)
    'Request Binary Write access, and lock out other
    'apps.
    Dim fd As Integer
    fd = FreeFile
    Open File For Binary Access Write Lock Read Write As #fd
    Put #fd, 1, db
    Close #fd
End Sub
