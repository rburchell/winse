Attribute VB_Name = "basMain"
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

'set to "DEBUG" to enable full logging.
'"NONE" disables logging to file. (really really not recommended!)
Public Const LoggingType = "DEBUG"
'the types of logging (for headers)
Public Const LogTypeBug = "BUG"
Public Const LogTypeError = "ERROR"
Public Const LogTypeWarn = "WARN"
Public Const LogTypeNotice = "NOTICE"
Public Const LogTypeDebug = "DEBUG"

'[ACCESS FLAGS]
Public Const AccFullAccess As String = "MmgoriIa"
Public Const AccFlagMaster As String * 1 = "M"
Public Const AccFlagCoMaster As String * 1 = "m"
Public Const AccFlagGetServNotices As String * 1 = "g"
Public Const AccFlagCanOperServ As String * 1 = "o"
Public Const AccFlagCanRootServ As String * 1 = "r"
Public Const AccFlagCanRootServInject As String * 1 = "i"
Public Const AccFlagCanRootServSuperInject As String * 1 = "I"
Public Const AccFlagCanMassServ As String * 1 = "a"
'[/ACCESS FLAGS]

Public Type ConfigVars
    ServerType As String
    '^Added this so we can use better ways of doing
    ' things if we have the right IRCd.  - Jason
    UplinkHost As String
    UplinkName As String
    UplinkPort As String
    UplinkPassword As String
    UplinkType As String
    ServerName As String
    'If it could be byte... I don't care, but NUMERICs
    'really should be... numeric. :P - aquanight
    ServerNumeric As Byte
    ' Changed to byte, 255 is the max, so there is no need for anything higher - Jason
    ServerDescription As String
    ServicesMaster  As String
    DefaultMessageType As Boolean
    GlobalTargets As String 'What Global sends to send something to everyone.
    InjectToOperServices As Boolean
End Type

Public Config As ConfigVars

'WinSe: WINdows SErvices, also a "pune" or "play on words" (wince, geddit??)
'... hasn't made me wince yet ^.- - aquanight
Public Const AppName = "winse"
Public Const AppVersion = "0.0.4.0"
Public Const AppCompileInfo = "sense_datum"
Public Const AppCompileDate = "2004/06/25-1400hours"

'UserModes is used so basFunctions.SetUserModes doesnt give a user an illegal mode.
'Yes, its a huge hack, but I cant think of another way to do it. NEED another way,
'as instr() is VERY VERY slow. --w00t
'Well, a few things:
'1) We want to be IRCd independent, and thus can't
'   really say what's "illegal".
    'True. --w00t
'2) My new parser idea is probably going to be a little
'   better than what is being used now :) . One thing
'   I plan on is a service callback to ask what should
'   be done about this mode. That way, a user getting +o
'   can receive OPER NEWS, and NickServ can unset +r on
'   those that aren't supposed to have it :) .
    'Bet that won't come till .NET. I'd like to try callbacks in vb6... --w00t
'Also, I'll get rid of the need for those ugly +, -,
'space thingies. -aquanight
Public Const UserModes = "iowghraAsORTVSxNCWqBzvdHtGp"
'My new parser idea is going to need these to be comma
'seperated like they are in 005 CHANMODES. I've
'provided a commented out version of what this will
'look like. And is the +/-/space _really_ necessary?
    'They are, I think. Can't remember why though. --w00t
'When it gets done, there will NEED to be 3 commas here
'and the +, -, and space won't be needed. - aquanight
Public Const ChannelModes2 = "be,fkL,l,psmntirRcOAQKVGCuzNSMT"
Public Const ChannelModes = "psmntirRcOAQKVGCuzNSMTbekfLl"
'and those that give permissions :P --w00t
    'We need to remember that in Unreal, +qa are treated as
    'lists, not prefixes. Plus, not all IRCds have them
    'defined. Thus we should have seperate variables for
    'defining modes to be given to Founders, SOPs, AOPs,
    'HOPs, and VOPs, and whatever else :) . - aquanight
    'Update: we don't need that yucky + character in
    'there, so out it goes :) .
Public Const ChanModesForAccess = "qaohv"
'Determining how many parameters to send is easy,
'simply use Len(*Privs) - 1. But let me warn you that
'the String() function won't work for this :) .
    'eh? Why not? Just use Len() and then mid starting at 1...? --w00t
Public Const FounderPrivs = "+qo"
Public Const CFounderPrivs = "+ao" 'or should we +q?
Public Const SOPPrivs = "+ao"
Public Const AOPPrivs = "+o"
Public Const HOPPrivs = "+h"
Public Const VOPPrivs = "+v"

'An idea I had if we decide to allow SUSPEND or FORBID
'of channels. When a channel is SUSPENDed or FORBIDden,
'it is effectively MLOCK'd and TopicLocked to the
'values set below.
Public Const SuspendMLock = "+Osnt"
Public Const SuspendTLock = "This channel is suspended."
Public Const ForbidTLock = "This channel is forbidden."

'I really think a seperate structure for user connection
'info and user nickserv data is necessary :P .
Public Type UserStructure
    Nick As String              'Nickname
    EMail As String             'User email. NOT CHECKED FOR VALIDITY!!
    Password As String          'User password.
    MemoID As Integer           'ID associated with memos in the memoserv database.
    Modes As String             'Usermodes
    HideEMail As Boolean        'Is email visible?
    Access As String            'Services access.
    Requests As Byte            'Flood level. Goes up by 1 on each request.
                                'When it hits 5, a warning. 10, a kill. 20, a gline (unless >= services admin)
                                'Flood level goes down by 1 every 2 seconds??
    MsgStyle As Boolean         'True=notice false=privmsg
    AbuseTeam As Boolean        'Abuse Team members can use services commands that otherwise, only the services master can use.
    IdentifiedToNick As String  'Holds nick that user has identified to. Blank if not identified.
    Channels As Collection      'Channels this user is on. (Use Channel ID as the value and key :) ).
    'Some extra stuff we might get from things like
    'Unreal IRCd :P .
    SignOn As Long              'Time Stamp of the user.
    SvsStamp As Long            '"Service stamp"
    UserName As String          'Ident (in USER or Identd reply).
    HostName As String          'User's real hostname.
    RealName As String          '"Real Name" of this user
    VirtHost As String          'Virtual Host, from stuff like GETHOST or NICKv2
    'Anything else services need to store?
    Custom As New Collection
End Type

Private Type ChannelAccess
    Nick As String
    Access As Byte 'must be < 255.
End Type
'bekfLl

Public Type ChannelStructure
    Name As String
    
    'Someone care to tell me why these were commented? -aquanight
        'Cause nothing to do with them had been implemented yet, and why does Topic
        'stuff need to be _tracked_ by services? Surely they can check if topicchange
        'is valid on the fly...--w00t
    'Topic Retention :) - aquanight
    Topic As String
    TopicSetBy As String
    TopicSetOn As String 'Not sure if this is really needed... --w00t
    FounderPassword As String
    MLock As String 'modes for mlock
    
    'access list stored in db only...
    'Better off caching it in memory. - aquanight
        'ok, but you're writing that bit :| --w00t
    TotalUsersOnAccessList As Integer
    AccessList() As ChannelAccess
    
    Modes As String
    
    TotalChannelUsers As Integer
    'Users() tracks the userid of users on a channel. -Dont need to track here,
    'rather in User structure.
    Users As Collection 'Users on this channel. (Use UserID as the value and key :) ).
    'That kind of limit is impractical, and for storing
    'only 1-5 characters max, allocating 10 is a waste
    'of space :P . -aquanight
    'Ok, I basically just totally changed this :)
    'Basically, each entry in this collection is key'd
    'by the CStr() of the user's UserID. -aquanight
    UsersModes As Collection
    'Now for the extended modes that require parameters (+flL etc)
    'We dont need to store them just now. --w00t
        'Oh what the heck, define them anyway :) -aquanight
    'I'm turning these arrays to collections because
    'messing with resizing arrays and what not is just
    'to bulky for my tastes :P . Declaring them New
    'should make sure we don't forget to init them, but
    '.NET isn't going to like it very much ;p .
    ' - aquanight
    Bans As New Collection
    Excepts As New Collection
    Invites As New Collection 'For hybrid :)
    ChannelKey As String
    FloodProtection As String 'chanmode +f
    OverflowChannel As String
    'This can be bigger than you think :) - aquanight
    OverflowLimit As Long
    'Anything else services need to store?
    Custom As New Collection
End Type

Public Type Service
    Nick As String
    Hostmask As String
    Name As String
End Type

'We should eventually move to Dynamic buffers here.
Public Channels(32767) As ChannelStructure
Public Users(32767) As UserStructure
Public NextFreeUserIndex As Integer
Public NextFreeChannelIndex As Integer

'32767 users total of services. Greater than this,
'and we die :/ Solution: Get a decent services package ;)
'One day, if I can be arsed, I will go around and change all occurences of
'total users being integer to long or something... but seriously, I doubt that
'this application could function on a net with > 200 users. --w00t
    'You'd be surprised what VB can do :) -aquanight
Public TotalUsers As Integer
'For channels, 32K is not very practical. Consider:
'32K users, 10 chans per users, 320K channels, overflow
'not good :) . But I'm not going to change it right now
'considering that the VB6 -> .NET move is going to keep
'these declared Integer (which is 4 bytes in .NET, which
'means 2 billion + max). Even the big dudes don't have
'even half of 2 billion USERS yet :P . - aquanight
    'Also, who is going to use winse who has 320K channels?!?! --w00t
Public TotalChannels As Integer 'again, 32767 limit :P should be plenty...

'This should be 1 > than the UBound of your array.
    'When I wrote stuff with totalservices and stuff like that, I didnt know about UBound :P --w00t
Public Const TotalServices = 12
'Since Option Base 0 applies, we're allocating extra space here. - aquanight
    'Yay dynamics. --w00t
Public Service(TotalServices - 1) As Service

'Again, I think this is better off as a dynamic buffer. -aquanight
    'Probably, but seriously. Who is ever going to get to 32767 elements? It would
    'take pretty serious services hammering to get there considering the buffers are
    'cleared once a second. --w00t
Public Buffer(32767) As String
Public BufferElements As Integer

Sub Main()
    'DO NOT REORDER THE SERVICES! eg chanserv (or whatever you call it) should be #0
    'If you change the order, you will see things like Agent setting channel topics (!)
    '--w00t
    basMain.TotalChannels = -1
    basMain.TotalUsers = -1
    'Let's parse our config :|
    basFileIO.ParseConfigurationFile (App.Path & "\winse.conf")
    
    'Note that you CAN have custom hostmasks (a sethost is issued) but I choose not to.
    'actually for aliases to work, the
    'hostname should generally be the same as the server
    'name (at the least, to avoid confusion). -aquanight
        'Who uses aliases, really. :P Besides, people like changing stuff. --w00t
    'I think a seperate RealName field would be nice :) -aquanight
        'Perhaps, but I cba atm :P --w00t
    Service(0).Nick = "ChanServ"
    Service(0).Hostmask = Config.ServerName '"channel-services." & DomainName
    Service(0).Name = "channel"
    
    Service(1).Nick = "NickServ" 'aka "the service that unreal loves to kill for no reason"
    Service(1).Hostmask = Config.ServerName '"nick-services." & DomainName
    Service(1).Name = "nickname"
    
    Service(2).Nick = "HostServ"
    Service(2).Hostmask = Config.ServerName '"hostmask-services." & DomainName
    Service(2).Name = "hostmask"
    
    Service(3).Nick = "BotServ"
    Service(3).Hostmask = Config.ServerName '"automation-services." & DomainName
    Service(3).Name = "automation"
    
    Service(4).Nick = "OperServ"
    Service(4).Hostmask = Config.ServerName '"operator-services." & DomainName
    Service(4).Name = "dictator"
    
    Service(5).Nick = "AdminServ"
    Service(5).Hostmask = Config.ServerName '"administrator-services." & DomainName
    Service(5).Name = "overlord"
    
    Service(6).Nick = "RootServ"
    Service(6).Hostmask = Config.ServerName '"master-services." & DomainName
    Service(6).Name = "master"
    
    Service(7).Nick = "Agent"
    Service(7).Hostmask = Config.ServerName '"blackglasses." & DomainName
    Service(7).Name = "smith"
    
    Service(8).Nick = "Global"
    Service(8).Hostmask = Config.ServerName '"noticer." & DomainName
    Service(8).Name = "noticer"
    
    Service(9).Nick = "MassServ"
    Service(9).Hostmask = Config.ServerName '"mass-services." & DomainName
    Service(9).Name = "wmd"
    
    Service(10).Nick = "MemoServ"
    Service(10).Hostmask = Config.ServerName '"memo-services." & DomainName
    Service(10).Name = "mailman"
    
    Service(11).Nick = "DebugServ"
    Service(11).Hostmask = Config.ServerName '"services." & DomainName
    Service(11).Name = "INVISIBLE"
    frmServer.Show
End Sub

Public Sub IntroduceUsers()
    Dim Nick As String
    Dim Host As String
    Dim Name As String
    Dim i As Integer
    For i = 0 To basMain.TotalServices - 1
        Nick = basMain.Service(i).Nick
        Host = basMain.Service(i).Hostmask
        Name = basMain.Service(i).Name
        Call basFunctions.IntroduceClient(Nick, Host, Name)
    Next i
End Sub

Public Sub HandlePrivateMessage(Buffer As String)
    Dim Message As String
    Dim Target As String
    Dim Sender As Integer
    Dim FirstColon As Integer
    Dim SecondColon As Integer
    Sender = basFunctions.ReturnUserIndex(basFunctions.GetSender(Buffer))
    
    If Sender = -1 Then
        Call basFunctions.NotifyAllUsersWithServicesAccess(Replace(Replies.SanityCheckInvalidIndex, "%n", "frmServer.tcpServer_DataArrival"))
        Exit Sub
    End If
    Target = basFunctions.GetTarget(Buffer)
    
    FirstColon = InStr(Buffer, ":")
    'SecondColon = InStr(FirstColon + 1, Buffer, ":")
    Message = Right(Buffer, Len(Buffer) - FirstColon)
    'Message = Left(Message, Len(Message))

    Select Case UCase(Target)
        Case "DEBUGSERV"
            Call sDebugServ.DebugservHandler(Message, Sender)
        Case "CHANSERV"
            Call sChanServ.ChanservHandler(Message, Sender)
        Case "NICKSERV"
            Call sNickServ.NickservHandler(Message, Sender)
        Case "HOSTSERV"
        Case "BOTSERV"
        Case "OPERSERV"
            Call sOperServ.OperservHandler(Message, Sender)
        Case "ADMINSERV"
            Call sAdminServ.AdminservHandler(Message, Sender)
        Case "ROOTSERV"
            Call sRootServ.RootservHandler(Message, Sender)
        Case "AGENT"
            Call sAgent.AgentHandler(Message, Sender)
        Case "MASSSERV"
            Call sMassServ.MassservHandler(Message, Sender)
    End Select
ExitSub:
'If we get an error, it is likely due to a messageflood that led to a kill.
End Sub
