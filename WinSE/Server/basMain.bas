Attribute VB_Name = "basMain"
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

'Defines the default for users().msgstyle True=notice false=privmsg
Public Const DefaultServiceMessageType = True

'We really need to make these into just plain config
'file entries... but let's get it stable first :>
' - aquanight
Public Const UplinkHost = "127.0.0.1"
Public Const UplinkName = "irc.dragons.net"
Public Const UplinkPort = "6667"
Public Const UplinkPassword = "dragonserv"

Public Const ServerName = "services.dragons.net"
Public Const ServerNumeric = "100"
Public Const ServerDescription = "Dragons IRC Network Services"

'WinSe: WINdows SErvices, also a "pune" or "play on words" (wince, geddit??)
'... hasn't made me wince yet ^.- - aquanight
Public Const AppName = "winse"
Public Const AppVersion = "0.0.3.3"
Public Const AppCompileInfo = "noesis"
Public Const AppCompileDate = "2004/06/14-1145hours"

Public ServicesMaster As String   'The first services root.

'UserModes is used so basFunctions.SetUserModes doesnt give a user an illegal mode.
'Yes, its a huge hack, but I cant think of another way to do it. NEED another way,
'as instr() is VERY VERY slow. --w00t
'aquanight: Well, a few things:
'1) We want to be IRCd independent, and thus can't
'   really say what's "illegal".
'2) My new parser idea is probably going to be a little
'   better than what is being used now :) . One thing
'   I plan on is a service callback to ask what should
'   be done about this mode. That way, a user getting +o
'   can receive OPER NEWS, and NickServ can unset +r on
'   those that aren't supposed to have it :) .
'Also, I'll get rid of the need for those ugly +, -,
'space thingies.
Public Const UserModes = " -+iowghraAsORTVSxNCWqBzvdHtGp"
'My new parser idea is going to need these to be comma
'seperated like they are in 005 CHANMODES. I've
'provided a commented out version of what this will
'look like. And is the +/-/space _really_ necessary?
'When it gets done, there will NEED to be 3 commas here
'and the +, -, and space won't be needed. - aquanight
'Public Const ChannelModes = "be,fkL,l,psmntirRcOAQKVGCuzNSMT"
Public Const ChannelModes = " -+psmntirRcOAQKVGCuzNSMTbekfLl"
'and those that give permissions :P
'We need to remember that in Unreal, +qa are treated as
'lists, not prefixes. Plus, not all IRCds have them
'defined. Thus we should have seperate variables for
'defining modes to be given to Founders, SOPs, AOPs,
'HOPs, and VOPs, and whatever else :) . - aquanight
Public Const ChanModesForAccess = "+qaohv"
'Determining how many parameters to send is easy,
'simply use Len(*Privs) - 1. But let me warn you that
'the String() function won't work for this :) .
Public Const FounderPrivs = "+qo"
Public Const CFounderPrivs = "+ao" 'or should we +q?
Public Const SOPPrivs = "+ao"
Public Const AOPPrivs = "+o"
Public Const HOPPrivs = "+h"
Public Const VOPPrivs = "+v"

Public Type UserStructure
    Nick As String       'Nickname
    EMail As String      'User email. NOT CHECKED FOR VALIDITY!!
    Password As String   'User password.
    MemoID As Integer    'ID associated with memos in the memoserv database.
    Modes As String      'Usermodes
    HideEMail As Boolean 'Is email visible?
    Access As Byte       'Services access. 0=none, 255=root etc
    Requests As Byte     'Flood level. Goes up by 1 on each request.
                         'When it hits 5, a warning. 10, a kill. 20, a gline (unless >= services admin)
                         'Flood level goes down by 1 every 2 seconds??
    MsgStyle As Boolean  'True=notice false=privmsg
    AbuseTeam As Boolean 'Abuse Team members can use services commands that otherwise, only the services master can use.
    IdentifiedToNick As String 'Holds nick that user has identified to. Blank if not identified.
End Type

Private Type ChannelAccess
    Nick As String
    Access As Byte 'must be < 255.
End Type
'bekfLl
Public Type ChannelStructure
    Name As String
    
    'Someone care to tell me why these were commented?
    ' - aquanight
    Topic As String
    TopicSetBy As String
    TopicSetOn As String 'Not sure if this is really needed... --w00t
    FounderPassword As String
    MLock As String 'modes for mlock
    
    'access list stored in db only...
    'Better off caching it in memory. - aquanight
    TotalUsersOnAccessList As Integer
    AccessList() As ChannelAccess
    
    Modes As String
    
    TotalChannelUsers As Integer
    'Users() tracks the userid of users on a channel.
    Users() As Integer
    'That kind of limit is impractical, and for storing
    'only 1-5 characters max, allocating 10 is a waste
    'of space :P .
    UsersModes() As String 'Hopefully, each user on chan wont have >10 modes ;)
    'Now for the extended modes that require parameters (+flL etc)
    'We dont need to store them just now. --w00t
    'Oh what the heck, define them anyway :)
    Bans() As String
    Excepts() As String
    ChannelKey As String
    FloodProtection As String 'chanmode +f
    OverflowChannel As String
    'This can be bigger than you think :) - aquanight
    OverflowLimit As Long
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
'aquanight: You'd be surprised what VB can do :) .
Public TotalUsers As Integer
'For channels, 32K is not very practical. Consider:
'32K users, 10 chans per users, 320K channels, overflow
'not good :) . But I'm not going to change it right now
'considering that the VB6 -> .NET move is going to keep
'these declared Integer (which is 4 bytes in .NET, which
'means 2 billion + max). Even the big dudes don't have
'even half of 2 billion USERS yet :P . - aquanight
Public TotalChannels As Integer 'again, 32767 limit :P should be plenty...

'This should be 1 > than the UBound of your array.
Public Const TotalServices = 12
'Since Option Base 0 applies, we're allocating extra
'space here. - aquanight
Public Service(TotalServices - 1) As Service

'Again, I think this is better off as a dynamic buffer.
Public Buffer(32767) As String
Public BufferElements As Integer

Sub Main()
    basMain.TotalChannels = -1
    basMain.TotalUsers = -1
    'Note that you CAN have custom hostmasks (a sethost is issued) but I choose not to.
    'aquanight: actually for aliases to work, the
    'hostname should generally be the same as the server
    'name (at the least, to avoid confusion).
    'I think a seperate RealName field would be nice :)
    basMain.ServicesMaster = "aquanight" 'Config anyone?
    Service(0).Nick = "ChanServ"
    Service(0).Hostmask = ServerName '"channel-services." & DomainName
    Service(0).Name = "channel"
    
    Service(1).Nick = "NickServ" 'aka "the service that unreal loves to kill for no reason"
    Service(1).Hostmask = ServerName '"nick-services." & DomainName
    Service(1).Name = "nickname"
    
    Service(2).Nick = "HostServ"
    Service(2).Hostmask = ServerName '"hostmask-services." & DomainName
    Service(2).Name = "hostmask"
    
    Service(3).Nick = "BotServ"
    Service(3).Hostmask = ServerName '"automation-services." & DomainName
    Service(3).Name = "automation"
    
    Service(4).Nick = "OperServ"
    Service(4).Hostmask = ServerName '"operator-services." & DomainName
    Service(4).Name = "dictator"
    
    Service(5).Nick = "AdminServ"
    Service(5).Hostmask = ServerName '"administrator-services." & DomainName
    Service(5).Name = "overlord"
    
    Service(6).Nick = "RootServ"
    Service(6).Hostmask = ServerName '"master-services." & DomainName
    Service(6).Name = "master"
    
    Service(7).Nick = "Agent"
    Service(7).Hostmask = ServerName '"blackglasses." & DomainName
    Service(7).Name = "smith"
    
    Service(8).Nick = "Global"
    Service(8).Hostmask = ServerName '"noticer." & DomainName
    Service(8).Name = "noticer"
    
    Service(9).Nick = "MassServ"
    Service(9).Hostmask = ServerName '"mass-services." & DomainName
    Service(9).Name = "wmd"
    
    Service(10).Nick = "MemoServ"
    Service(10).Hostmask = ServerName '"memo-services." & DomainName
    Service(10).Name = "mailman"
    
    Service(11).Nick = "DebugServ"
    Service(11).Hostmask = ServerName '"services." & DomainName
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
    Target = basFunctions.GetTarget(Buffer)
    
    FirstColon = InStr(Buffer, ":")
    SecondColon = InStr(FirstColon + 1, Buffer, ":")
    Message = Right(Buffer, Len(Buffer) - SecondColon)
    Message = Left(Message, Len(Message)) ' - 2)

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
