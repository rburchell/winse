VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "IIRCd"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'Support flags. I suppose they are better than having the action routines return values...
'The flag is passed as an argument...
'A function corresponding to a feature that isn't supported should do nothing. However, it is acceptable for
'said program to raise the E_NOTIMPL (&H80004001) Automation error.
Public Enum IRCdSupport
    SUPPORT_ISIRCD = 0      'Must always be True. If a False is returned, the ircd type will be invalid. Useful if we need to disable a protocol temporarily.
    SUPPORT_HASKILL         'IRCd has KILL command (what doesn't?).
    SUPPORT_HASSVSKILL      'IRCd has a SuperKill (SVSKILL).
    SUPPORT_SVSKILLACK      'Require IRCd acknowledgement of SVSKILLs.
    SUPPORT_HASNICKHACK     'Has user nickname hacking (SVSNICK).
    SUPPORT_HASNICKJUPE     'Has special method for juping a nick (like SVSHOLD or TKL + Q H nick etc).
    SUPPORT_HASVHOST        'IRCd has Vhost support (not bahamut hostmasking!).
    SUPPORT_HASVIDENT       'IRCd has VIdent support (NOT bahamut hostmasking!).
    SUPPORT_HASUMODEHACK    'Has Usermode hacking (SVSMODE).
    SUPPORT_CHANJUPEKICK    'Channel jupe method will cause servers to boot everyone out.
    SUPPORT_HASSERVERJUPE   'Has speical method for juping a server (IRCu will need to use this).
    SUPPORT_HASNOOPERS      'Has server-wide oper disable (SVSNOOP).
    SUPPORT_HASACCOUNT      'Has method of setting the account (nick group).
    SUPPORT_CHANGEACCOUNT   'Has method of changing the account (nick group) (IRCu: Don't use this.)
    SUPPORT_USERHOSTBAN     'Has method for setting a network-wide user@host ban (netwide K:Line) (AKILL).
    SUPPORT_NICKBAN         'Has method for setting a nickname ban (SQLINE).
    SUPPORT_GCOSBAN         'Has method for setting a realname ban (SGLINE).
    SUPPORT_IPADDRBAN       'Has method for setting an IP ban (SZLINE, AKILL *@ip).
    SUPPORT_TEMPAKILL       'Supports timed user@host bans.
    SUPPORT_TEMPNICKBAN     'Supports timed nickname bans.
    SUPPORT_TEMPGCOSBAN     'Supports timed realname bans.
    SUPPORT_TEMPIPADDRBAN   'Supports timed IP bans.
    SUPPORT_DELAKILL        'Supports removing user@host bans before they expire.
    SUPPORT_DELNICKBAN      'Supports removing nickname bans before they expire.
    SUPPORT_DELGCOSBAN      'Supports removing realname bans before they expire.
    SUPPORT_DELIPBAN        'Supports removing IP bans before they exipre.
    SUPPORT_USESSERVID      'Uses Server Identifiers (numerics)
    SUPPORT_USESCLIENTID    'Uses Client Identifiers (numerics)
End Enum

'The base interface for IRCd protocol classes.

'All IRCd classes must implement the functions below.

'Services Functionality MUST NOT be implemented in a protocol module! They are for the
'sole purpose of handling the server<->server communication. Only in the processing
'of received commands, shall protocol modules interfere with the internal state of
'services, and this processing should only modify that state which the IRCd indicates
'should be changed.

'Therefore the only exception is the modification of the Users, Channels, or Servers array which must be
'done only inside the ParseCmd()

'Support functions...
Public Function HasSupport(ByVal SupportType As IRCdSupport) As Boolean

End Function

'Introduction Functions

'Send the commands to introduce oneself, using the data from basMain.Config.
Public Sub IntroduceSelf()

End Sub

'Create a Client ID. This is only used for server-server protocol, and should be formatted how the target
'IRCd expects it. For example, in IRCu, this would be a 5 character number in Base64. For Unreal, this will
'be in ASCII format. Use vbNullString if CIDs aren't used on the ircd.
Public Function CreateCID() As String

End Function

'Create a Server ID. This is only used for server-server protocol, and should be formatted how the target
'IRCd expects it. For example, in IRCu, this would be a 2 character base64 number. For Unreal, this will be
'in ASCII format. It is preferred that services have a pool of SIDs they can use for servers.
'Use vbNullString if SIDs aren't used on the ircd.
Public Function CreateSID() As String

End Function

'Introduce a client on the given server.
Public Sub IntroduceClient(ByVal Nick As String, ByVal UserName As String, ByVal HostName As String, ByVal RealName, ByVal VHost As String, ByVal UserModes As String, ByVal CID As String, ByVal Server As String)

End Sub

'Introduce a server behind the given server.
Public Sub IntroduceServer(ByVal ServerName As String, ByVal Hops As Long, ByVal SID As String, ByVal Description As String, ByVal BehindServer As String)

End Sub

'Quit a client.
Public Sub RemoveClient(ByVal Nick As String, ByVal Reason As String)

End Sub

'SQuit a server.
Public Sub RemoveServer(ByVal Sender As String, ByVal Server As String, ByVal Reason As String)

End Sub

'Enforcement Functions

'KILL a user.
'SVSKillOK is True if the KILL reason was not determined by a user (with the sole
'exception of Agent EXIT).
Public Sub KillUser(ByVal Source As String, ByVal SVSKillOK As Boolean, ByVal User As String, ByVal Reason As String)

End Sub

'Force a nickchange.
Public Sub ForceNickChange(ByVal Source As String, ByVal Target As String, ByVal NewNick As String)

End Sub

'Set a hold on a NICK.
Public Sub HoldNick(ByVal Source As String, ByVal Nick As String)

End Sub

'Release a hold on a NICK.
Public Sub ReleaseNick(ByVal Source As String, ByVal Nick As String)

End Sub

'Set a Virtual Host for a user.
Public Sub SetVHost(ByVal Source As String, ByVal Nick As String, ByVal VHost As String)

End Sub

'Set a Virtual Ident (Username) for a user.
Public Sub SetVIdent(ByVal Source As String, ByVal Nick As String, ByVal VIdent As String)

End Sub

'Forcefully change a user's modes.
Public Sub SetUserModes(ByVal Source As String, ByVal Nick As String, ByVal Modes As String)

End Sub

'Set a hold on a channel. IRCds that don't support special methods of holding a channel could just make
'the source join and lock down the channel. Protocol class may assume the channel is empty.
Public Sub HoldChannel(ByVal Source As String, ByVal Channel As String)

End Sub

'Release a hold on a channel. Should just generally reverse HoldChannel.
Public Sub ReleaseChannel(ByVal Source As String, ByVal Channel As String)

End Sub

'Set a hold on a server (more formally called a JUPE).
Public Sub HoldServer(ByVal Source As String, ByVal Server As String)

End Sub

'Release or UNJUPE a server.
Public Sub ReleaseServer(ByVal Source As String, ByVal Server As String)

End Sub

'Set NOOP on the server.
Public Sub SetServerNoOpers(ByVal Source As String, ByVal Server As String)

End Sub

'Unset NOOP on the server.
Public Sub UnsetServerNoOpers(ByVal Source As String, ByVal Server As String)

End Sub

'Set the user account name for the first time.
'Note that "account" is just a fancy name for Nick Group.
Public Sub SetAccount(ByVal Source As String, ByVal Target As String, ByVal account As String)

End Sub

'Change the user account name.
'Note that "account" is just a fancy name for Nick Group.
Public Sub ChangeAccount(ByVal Source As String, ByVal Target As String, ByVal account As String)

End Sub

'Add a Network-Wide Temporary KLINE, also called a GLINE.
Public Sub AddTempNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String)

End Sub

'Add a Network-Wide Permanent KLINE, also called a GLINE.
Public Sub AddPermNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String)

End Sub

'Remove a Network-Wide KLINE, also called a GLINE.
Public Sub DeleteNetworkUserhostBan(ByVal Source As String, ByVal Mask As String)

End Sub

'Add a Network-Wide Temporary ZLINE, also called a GZLINE.
Public Sub AddTempNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String)

End Sub

'Add a Network-Wide Permanent ZLINE, also called a GZLINE.
Public Sub AddPermNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String)

End Sub

'Remove a Network-Wide ZLINE, also called a GZLINE.
Public Sub DeleteNetworkIPBan(ByVal Source As String, ByVal Mask As String)

End Sub

'Add a Network-Wide Temporary QLINE, also called a SQLINE.
Public Sub AddTempNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String)

End Sub

'Add a Network-Wide Permanent QLINE, also called a SQLINE.
Public Sub AddPermNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String)

End Sub

'Remove a Network-Wide QLINE, also called a SQLINE.
Public Sub DeleteNetworkNickBan(ByVal Source As String, ByVal Mask As String)

End Sub

'Add a Network-Wide Temporary Realname Ban.
Public Sub AddTempNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String)

End Sub

'Add a Network-Wide Permanent Realname Ban.
Public Sub AddPermNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String)

End Sub

'Remove a Network-Wide Realname Ban.
Public Sub DeleteNetworkRealnameBan(ByVal Source As String, ByVal Mask As String)

End Sub

'Valid Usermodes
Public Property Get UserModes() As String

End Property

'Messaging
Public Sub SendPrivMsg(ByVal Source As String, ByVal Target As String, ByVal Notice As Boolean, ByVal Text As String)

End Sub

Public Sub SendNumeric(ByVal Target As String, ByVal Numeric As Integer, ByVal Text As String)

End Sub

Public Sub Wallopers(ByVal Source As String, ByVal Message As String)

End Sub

Public Sub SendToUMode(ByVal Source As String, ByVal UMode As String, ByVal Message As String)

End Sub

'Channel Functions

'Join a client to a channel.
Public Sub JoinChannel(ByVal Source As String, ByVal Channel As String)

End Sub

'Part a client from a channel.
Public Sub PartChannel(ByVal Source As String, ByVal Channel As String, ByVal Reason As String)

End Sub

'Kick a client from a channel.
Public Sub KickUser(ByVal Source As String, ByVal Channel As String, ByVal Victim As String, ByVal Reason As String)

End Sub

'Change the topic on a channel.
Public Sub ChannelTopic(ByVal Source As String, ByVal Channel As String, ByVal Topic As String, ByVal SetBy As String, ByVal SetOn As Long)

End Sub

'Change modes on the channel.
Public Sub ChannelMode(ByVal Source As String, ByVal Channel As String, ByVal Modes As String)

End Sub

'Create a channel. Generally this is just JOIN and MODE +o, or SJOIN @Nick.
Public Sub CreateChannel(ByVal Source As String, ByVal Channel As String)

End Sub

'Burst a channel. For older IRCds this may require just sending tons of JOIN MODE etc. IRC2.11 at least gives
'NJOIN for sending the users and status. Hybrid/bahamut IIRC gives us SJOIN which is nice because we have TS
'there.
Public Sub BurstChannel(ByVal Source As String, ByVal Channel As String, ByVal ts As Long, ByVal Modes As String, ByVal ModeParams As String, ByRef Users() As String, ByRef WantModes() As String, ByRef Bans() As String, ByRef Exempts() As String, ByRef Invites() As String)

End Sub

'All channel modes supported by the IRCd. Only non-"channel status" modes should be here. This is in 005
'CHANMODES= format.
Public Property Get ChanModes() As String

End Property

'The MODE CHARACTER (NOT PREFIX) for Voice Privilege. There is probably only a few rare oddball IRCds that
'don't support Voice or use a different character. Everyone else should just return 'v'.
Public Property Get VoiceChar() As String

End Property

'The MODE CHARACTER (NOT PREFIX) for Halfop Status. There are two major IRCds that don't support halfop that
'WinSE probably will officially support. Namely, stock IRCu, Bahamut, and PTLink ircds do NOT have HalfOp.
'Most other IRCds that do support halfop will probably set this to h. The IRCds mentioned will have this
'set to an empty string.
Public Property Get HalfopChar() As String

End Property

'The MODE CHARACTER (NOT PREFIX) for ChanOp Status. There is probably only a few rare oddball IRCds that
'don't support Ops or use a different character. Everyone else should just return 'o'.
Public Property Get ChanOpChar() As String

End Property

'The MODE CHARACTER (NOT PREFIX) for Protected Status. Of the IRCds to be supported by WinSE, only Unreal
'supports Protected Users without modification(s). Note that protected != owner. PTLink has a +a, but it
'means Owner, not Protected/Admin as in Unreal. Stock IRCu/bahamut/hybrid will just return an empty string
'here.
Public Property Get ProtectChar() As String

End Property

'The MODE CHARACTER (NOT PREFIX) for Owner Status. Unreal, PTLink, and the not-to-be-supported IRCd2.11
'support an Owner mode. Note that Unreal's owner flag is +q, PTLink's is +a. If a brave soul so dares to
'attempt to make an IRCd 2.11 class, use +O for this, but I STRONGLY DISCOURAGE supporting anything other
'than #standard channels, which doesn't use +O.
Public Property Get OwnerChar() As String

End Property

'The MODE CHARACTER for Ban List. There is probably only a few rare oddball IRCds that don't support Bans or
'use a different character. Everyone else should just return 'b'.
Public Property Get BanChar() As String

End Property

'The MODE CHARACTER for Ban Exception. Stock IRCu does not support exempts. Not too sure about PTLink, and
'only recent versions of Bahamut have exempt. In most cases, this will be 'e'.
Public Property Get ExemptChar() As String

End Property

'The MODE CHARACTER for Invite Exceptions. Stock IRCu, stock UnrealIRCd, and probably earlier versions of
'bahamut do NOT have InvEx. (Unreal is developing InvEx, so we may see it in CVS soon :> .) In most cases,
'this will be 'I'.
Public Property Get InvExChar() As String

End Property

'Well, sendings all good and everything, but I think we ought to have something to RECEIVE too.
'Actual execution of commands could be done in two ways:
' - WinSE currently uses CallByName to invoke a procedure with the given Command name. Use a prefix so that
'   commands named the same as VB keywords can still be used.
' - A big Select Case with all the commands and any synonyms (such as tokens in Unreal and P10 IRCds).
'And of course come up with your own way if you so choose.
Public Sub ParseCmd(ByVal Buffer As String)

End Sub
