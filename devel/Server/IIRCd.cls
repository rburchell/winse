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

'Constants for the KillUser return value.
Public Enum KillSupport
    KILL_NOSUPPORT = 0 'Not supported.
    KILL_SUPPORTED = 1 'Supported. User.KillUser should dispose the user object.
    KILL_NODISPOSE = 2 'Supported. User.KillUser should NOT dispose the user object.
End Enum

'The base interface for IRCd protocol classes.

'All IRCd classes must implement the functions below.

'Services Functionality MUST NOT be implemented in a protocol module! They are for the
'sole purpose of handling the server<->server communication. Only in the processing
'of received commands, shall protocol modules interfere with the internal state of
'services, and this processing should only modify that state which the IRCd indicates
'should be changed.

'Introduction Functions

'Send the commands to introduce oneself, using the data from basMain.Config.
Public Sub IntroduceSelf()

End Sub

'Create a Client ID. This is only used for server-server protocol, and should be formatted how the target
'IRCd expects it. For example, in IRCu, this would be a 5 character number in Base64. For Unreal, this will
'be in ASCII format.
Public Function CreateCID() As String

End Function

'Create a Server ID. This is only used for server-server protocol, and should be formatted how the target
'IRCd expects it. For example, in IRCu, this would be a 2 character base64 number. For Unreal, this will be
'in ASCII format. It is preferred that services have a pool of SIDs they can use for servers.
Public Function CreateSID() As String

End Function

'Introduce a client on the given server.
Public Sub IntroduceClient(ByVal Nick As String, ByVal UserName As String, ByVal HostName As String, ByVal RealName, ByVal VHost As String, ByVal UserModes As String, ByVal cid As String, ByVal Server As String)

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
Public Function KillUser(ByVal Source As String, ByVal SVSKillOK As Boolean, ByVal User As String, ByVal Reason As String) As KillSupport

End Function

'Force a nickchange. If the protocol does not allow this to be done, the function
'should return False. When this happens, Nick enforcement will proceed to try KillUser.
Public Function ForceNickChange(ByVal Source As String, ByVal Target As String, ByVal NewNick As String) As Boolean

End Function

'Set the user account name.
Public Function SetAccount(ByVal Source As String, ByVal Target As String, ByVal Account As String) As Boolean

End Function

'Change the user account name.
Public Function ChangeAccount(ByVal Source As String, ByVal Target As String, ByVal Account As String) As Boolean

End Function

'Add a Network-Wide Temporary KLINE, also called a GLINE. Return False if the IRCd
'doesn't allow this. Expiry is in seconds.
Public Function AddTempNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean

End Function

'Add a Network-Wide Permanent KLINE, also called a GLINE. Return False if the IRCd
'doesn't allow this.
Public Function AddPermNetworkUserhostBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean

End Function

'Remove a Network-Wide KLINE, also called a GLINE. Return False if the IRCd doesn't
'allow this.
Public Function DeleteNetworkUserhostBan(ByVal Source As String, ByVal Mask As String) As Boolean

End Function

'Add a Network-Wide Temporary ZLINE, also called a GZLINE. Return False if the IRCd
'doesn't allow this. Expiry is in seconds.
Public Function AddTempNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean

End Function

'Add a Network-Wide Permanent ZLINE, also called a GZLINE. Return False if the IRCd
'doesn't allow this.
Public Function AddPermNetworkIPBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean

End Function

'Remove a Network-Wide ZLINE, also called a GZLINE. Return False if the IRCd doesn't
'allow this.
Public Function DeleteNetworkIPBan(ByVal Source As String, ByVal Mask As String) As Boolean

End Function

'Add a Network-Wide Temporary QLINE, also called a SQLINE. Return False if the IRCd
'doesn't allow this. Expiry is in seconds.
Public Function AddTempNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean

End Function

'Add a Network-Wide Permanent QLINE, also called a SQLINE. Return False if the IRCd
'doesn't allow this.
Public Function AddPermNetworkNickBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean

End Function

'Remove a Network-Wide QLINE, also called a SQLINE. Return False if the IRCd doesn't
'allow this.
Public Function DeleteNetworkNickBan(ByVal Source As String, ByVal Mask As String) As Boolean

End Function

'Add a Network-Wide Temporary Realname Ban. Return False if the IRCd doesn't allow
'this. Expiry is in seconds.
Public Function AddTempNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Expiry As Long, ByVal Reason As String) As Boolean

End Function

'Add a Network-Wide Permanent Realname Ban. Return False if the IRCd doesn't allow
'this.
Public Function AddPermNetworkRealnameBan(ByVal Source As String, ByVal Mask As String, ByVal Reason As String) As Boolean

End Function

'Remove a Network-Wide Realname Ban. Return False if the IRCd doesn't allow this.
Public Function DeleteNetworkRealnameBan(ByVal Source As String, ByVal Mask As String) As Boolean

End Function

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
'don't support Voice or use a different character. Everyone else should just return 'o'.
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
'this will be 'e'.
Public Property Get InvExChar() As String

End Property

'Well, sendings all good and everything, but I think we ought to have something to RECEIVE too.
Public Sub ParseCmd(ByVal Buffer As String)

End Sub
