Attribute VB_Name = "NOTES"
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

'Regards to:
' w00t[w00t@netronet.org] - Coding
' Tron[tron@ircd-net.org] - I stole his UnixTime module. (vbircd)

'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'CHANGELOG
'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'Current Notices:
' -This is a pre-alpha release. Bugs are to be expected, especially as we are
'  currently in feature mode. Report all bugs to w00t@netronet.org
' -We really need to make replies for all commands (esp agent) and use them.

'ToDo:
' -Check for access to run list, and to view email address...
'  perhaps dont hide at all, since only access 10+ able to run...?
' -NS REGISTER doesnt return a successful message.
' -FJOIN and FPART seem to lag some...
' -CS doesnt always seem to successfully set the topic of a registered channel.
' -CS isnt setting channel modes of registered channel.
' -Make QUIT _also_ destroy channel if necessary.

'Services:
' ChanServ  [CS]  AdminServ [AS]
' NickServ  [NS]  RootServ  [RS]
' HostServ  [HS]  Agent     [AG]
' BotServ   [BS]  Global    [GN]
' OperServ  [OS]  MassServ  [MsS]
' MemoServ  [MS]  Core      [CO]
'[-----------------------------------]
'Services Permission Levels:
' 100 - Services Root Administrator (aka Master)
'  99 - Services Administrator (aka comaster) (unlimited)
'  50 - Services Operator
'  10 - Services User
' ChanServ  0  AdminServ  99
' NickServ  0  RootServ   100
' HostServ  10  Agent     Any, with AbuseTeam flag
' BotServ   50  Global    n/a
' OperServ  10  MassServ  50
' MemoServ  0
'[-----------------------------------]
'Suggested services access for a net of, 400 people:
' (if this would even RUN on a net of 400...)
' 1 SRA ] -Mostly admin position
' 1 SA  ] -Mostly admin position
' 3 SO  ] -Basic admin, mostly user assistance. (ie setting a bot up)
' 10 SU ] -Mostly a "helper" role (ie report abuse for abuseteam checking)
' Perhaps around 5-8 people with abuse team access.
'[-----------------------------------]

'18/06/2004 - aquanight
' -[All][Fix] Option Explicit added to all modules.
'             More variables declared.
' -[All][Fix] Added explicit type specifications and
'             changed some Functions to Subs because
'             they don't really return anything :) .
' -[CO] [Fix] Did a bunch of code cleanups. Mostly in
'             basFunctions.
' -[CO] [Fix] Replaced MSWinSock with a .NET/COM
'             component. This should make things a bit
'             more stable :) .
'-- Notes for this version --
'Probably going to go through and turn parameters to
'ByVal. As it is, almost all parameters are ByRef, and
'that prevents us from (ab)using type-casting when
'passing arguments. It can also have unexpected effects
'if we use parameter mutiliation in a function :S (see
'KillUser for an example).
'Also, I think a good idea may be to turn the service
'modules into classes instead. They could then handle
'their own introduction a' la Class_Initialize/Sub New.
'This way, we can "reconnect" a service by simply
'destroying the object and recreating it. This also
'allows us to (ab)use late-binding with commands to
'make it much more... easier? An example signature for
'this method could be:
'Public Sub Kill(ByVal Sender As Integer, Args() As String)
'We can use CallByName to invoke this function. Would
'make for much cleaner parsing :) .
'-- End Notes --
'15/06/2004
' -[CO] [Bug] Undeclared variables declared
' -[AS] [Bug] Option Explicit enabled.
'14/06/2004
' -[CO] [Bug] Fixed a bug with PRIVMSG handling.
' -[CO] [Bug] PART now only removes a chan from array _if necessary_
' -[CO] [Bug] Fixed bug in PRIVMSG handling that caused an exponential
'             slowdown proportional to the number of clients.
' -[CO] [Feature] Added modular buffer parser, means cleaner code!
' -[CS] [Bug] Tidied stuff up.
' -[OS] [Bug] Fixed RTE on OS GLOBAL caused by a change to the core.
'09/05/2004
' -[CO] [Feature] Added logging (atm only messages, doesnt log to file)
' -[CO] [Feature] Channels deleted from array.
' -[CO] [Bug] Fixed bug handling JOIN event that caused CS to set channel topic
'             and modes each time a user joined.
' -[CS] [Bug] Chanserv was setting topic on _any_ channel, regardless of state.
' -[AG] [Feature] Started to turn OPTION EXPLICIT on.
' -[AG] [Feature] Added FJOIN
' -[AG] [Feature] Added FPART
'08/05/2004
' -Incremented version 0.0.2.4 -> 0.0.3.3 build description posit -> noesis
' -[CO] [Bug] Fixed server killing NS and CS. They were sending commands
'              before they had sent NICK and USER to the remote server.
' -[CO] [Feature] Buffering of sends added.
'06/05/2004
' -Added GPL notices.
' -Incremented version 0.0.1.8 -> 0.0.2.4 and build description rootage -> posit
' -[CO] [Bug] IsBot attribute added to IntroduceUser meaning that bots can
'             (only theoretically :P) recieve channel messages.
' -[CO] [Bug] Fixed bug resulting from setting TotalUsers initial value to -1
'             (always overwrote array(0)... meaning that >1 user connected
'             stuffed everything up.
' -[CO] [Bug] TotalUsers was always one more than the total user count.
' -[CS] [Feature] REGISTER added.
' -[CS] [Feature] Sets mlock, and topic sucessfully.
' -[NS] [Bug] Fixed a yuckky nesting problem. Didnt cause problems, but looked bad.
' -[NS] [Bug] Removed the NICK parameter out of both REGISTER and IDENTIFY
' -[NS] [Feature] LIST added.
' -[AG] [Feature] UNIDENTIFY added.
' -[AS] [Bug] ACCESS was setting the val on the _sender_ nick in the db,
'             not the target nick. I thought I fixed this yesterday...
'05/05/2004
' -[CO] [Feature] Added channel structure, for preliminary support of chanserv.
' -[CO] [Feature] basUnixTime stolen from vbIRCd :P Means we can actually send timestamps!
' -[CO] [Bug] Changed NAME attribute of UserStructure to NICK.
' -[NS] [Bug] SET COMMUNICATION now saves to db for registered nicks.
' -[NS] [Feature] IDENTIFY now checks if user is _the_ services master, and sets access=100
'                 just in case someone modified their permissions.
' -[AS] [Feature] SET removed for now. Not needed.
' -[AS] [Feature] ACCESS added.
' -[AS] [Feature] Now uses the new parameter array system, rather than the old seperator way.
' -[AS] [Feature] SET ADDABUSTEAM AND DELABUSETEAM merged into ABUSETEAM ADD nick and ABUSETEAM DEL nick
' -[AS] [Bug] Abuse team modification would set on the _wrong_ user. It was changing
'             (in the db) on the _sender_ not the target user.
'04/05/2004
' -[CO] [Bug] Now correctly tracks identification to nicks and nickchanges.
' -[RS] [Feature] RAW added
' -[AG] [Feature] EXIT added
' -[AG] [Feature] NICK added
' -[AG] [Feature] KICK added
' -[AG] [Feature] KILL added
' -[AS] [Bug] Adminserv now saves abuseteam status for registered nicks ;)
' -[MsS] [Feature] SERVJOIN introduced. Made a function in basFunctions. (also gives +qo)
' -[MsS] [Feature] SERVPART introduced. Made a function in basFunctions.
' -[NS] [Bug] Registering the services master nick didnt get you access level of 100
'             as it should :P
'03/05/2004
' -Incremented version 0.0.1.2 -> 0.0.1.8 and build description esthetic -> rootage
' -[CO] [Bug] Removed Public vars: PASS PROTOCTL and SERVER from basMain
' -[CO] [Bug] Removed PROTOCTL alltogether. We want RFC as far as possible :P
' -[CO] [Feature] Option Explicit enabled. on frmServer and basFunctions
' -[AG] [Feature] UMode added
' -[NS] [Feature] Added some more reporting code.
' -[NS] [Bug] If < 2 parameters passed to identify, module would exit silently.
' -[NS] [Bug] If nick was already registered, errmsg send- then register anyway.
'02/05/2004
' -Optomised a lot of the code, including the parsing of parameters through spaces,
'  instead of getting them manually and guessing which one we needed :|
' -A fair bit of the framework is now complete, therefore incremented version
'  0.0.0.1 -> 0.0.1.2
' -Today's task: Access lists and more module API functions.
' -Nick changes no longer break services. It tracks the nickchanges ;) yay
' -Made pseudoclient introduction modular ready for botserv.
' -Made masserv help
' -Added debugserv so I dont have to add debug commands to adminserv which i then have
'  to remove after i finish ;)
' -Began the adding of a permissions based system.
' -Botserv stub added, not quite yet finished.
' -Began the adding of database routines leading up to NS register/NS identify.
' -YAY ME! Rudimentary NS register/identify added!!!!!!!!!!!!!
' -Fixed floodlevels (the parameter parsing system broke them)
'01/05/2004
' -INCREMENTED BUILD DESCRIPTION: chrysantheum -> esthetic
' -Wow. A version that actually compiles after all these changes...
' -Added module Replies - So we can eventually use different languages! :D
' -Began using numeric descriptors to track users rather than passing the nickname
' -Added service name - Default to "Services"
' -Fixed bug in basFunctions.GetTarget that meant it returned the wrong parameter.
' -Introduced user tracking via NICK and QUIT
' -Tracking of user modes
' -Services class created. Attributes: Nick, Hostmask
' -Added so user can use nickserv set communication to choose if they want services to notice, or privmsg.
' -Added masserv pseudoclient ready ;)
' -Added floodlevels
'30/04/2004
' -Project start



        'LogAction = "---------------------------------------------------"
        'LogAction = LogAction & vbCrLf & "   " & ServerName & " nRC[" & AppVersion & "] "
        'LogAction = LogAction & vbCrLf & "       " & AppCompileDate & " CompileInfo=" & AppCompileInfo
        'LogAction = LogAction & vbCrLf & "       UserModes=" & AvailableUserModes & " ChannelModes=" & AvailableChannelModes
        'LogAction = LogAction & vbCrLf & "---------------------------------------------------"
        'LogAction = LogAction & vbCrLf & Date & "-" & Time & "| Begin INIT"
        'Call basFunctions.LogEvent(LogAction)
        'LogAction = ""


'THE BELOW WERE FROM nRC -- I gutted nRC to do these services ;)

'28/12/2003
' Added compiler const ReleaseDescriptor. Eventually will be used to create a more
' "verbose" mode.
'19/12/2003
' -Removed 3 global vars and added the Server control to replace them. (via properties)
'18/12/2003
' -Began work on nCU - The remote config tool.
' -Renamed global var Password ServicesPassword - Because of nCU
' -Added global var ConfigurationPassword - For nCU
' -Added a numeric prefix to welcome messages so config tool knows to ignore.
'17/12/2003
' -Renamed olines.db to nrc-config.db and began to make it more a general management file.
' -Ok. So I didnt fix the memory leak yesterday. So today, I rewrote the handling of the
'  user structure and made the whole connections handling less dynamic for a small server.
'  50 connections are always loaded, and never unloaded. That should save some CPU (and perhaps memory)
'  Hopefully it will also deal with the memory leak.
' -Right. It seems fixed...
' -Mostly a documentation day, as well as adding old bugs to the new database!!!
' -Added an invisible server mode. Using option in nrc-vonfig.db [nRC] OperationState.
'  Either "gui" or "nogui"
' -Added TotalConnectionsToLoad in nrc-config.db. Set to max expected connections.
'  Preloads to save cpu. Will use more memory than dynamic mode though in the short term.
'16/12/2003
' -tcpServer memory leak fixed (hopefully). This was due to some BodgyBobbin(tm) coding.
'  (I referenced intMaxClients - A variable that was removed WEEKS ago!!!!)
' -Have designed and implemented a bugtracking database to replace the above "Known Bugs"
'  section. Yay!
' -Prevented potential buffer overflow :| erk... I didnt think these existed...
'  Thankfully, due to the way this app works, we really only need to check for them in
'  one place.
' -Usermode +k (See all kills). Implemented via basFunctions.NotifyOfKill
' -Fixes to services password.
' -basFunctionsIO created. Holds IO specific functions such as SendDataToClient.
' -Removed HasUserGotMode. Now useless. Still there just in case.
' -Remembered that chanmode +s is actually implemented *blushes* *updates supported modes*
' -+U can override +O
' -UMODE modularised.
' -Only +U can override +T
' -Began implementation of admin levels concept.
' -Users cannot set modes higher than they have.
' -Services can set modes (AccessLevel=8)
' -+N only settable by services (O:block)
'15/12/2003
' -Reached 1990 lines of code.
' -Furthur thought-out concept for +Uq & other admin levels.
' -Worked on documentation.
' -Fixed: CHSERV:KickU (+U kick not messaging a channel)
' -Remote intro message fixes
' -Minor client fixes
' -Began implementation of protocol changes to make better!
' -Made client SAVE config (grrr)
' -Globalised client config to save accessing the HD each time
' -On client, made "server to connect to" customisable.
' -Minor cosmetic fixes (lots)
' -Fixed client RTEs (hopefully)
' -Updated ToDos
' -Added umode +H
' -Did a mini rewrite of USSERV:Whois to make a tad more efficient ;) yay!
'14/12/2003
' -Started working on documentation
' -Made supported-modes display only IMPLEMENTED modes ;) lol!
' -Removed unnecesssary public variable - Wasnt even referred to in code any more!!!
' -Usermodes +Uq.
' -Rewrote CHSERV:KickU - Mainly due to implementation of +Uq users.
' -Added OPSERV:KillU - Kill User (Removes a user from the server). Note: At current, causes
'  an RTE on the client end.
' -Added SendGlobalMessageToOperators - Sends a message to all with access > 0
' -Changed GlobM into a modularised function - SendGlobalMessage
' -Fix for IRC-apology message - used to turn mIRC nick into "Welcome" :) haha!
' -Removed services debug commands. No longer required for quite a long time.
' -Added SESERV:GlobM (GlobalMessage) - Sends a message to all users.
' -REALLY made client window scroll now ;)
' -Some TYPE changes to save memory.
' -Finalised server intro stuff that is sent upon connect.
' -Changed compile date into a global constant.
'13/12/2003
' -Expanded +I support... bwahahaha... Arent shown in userlists and now have
'  NO join\part message! LOL!!!! this has led me to totally BEWILDER one beta tester...
'  I didnt tell him of the changes, and had 2 invisibles in there with him! LOL!
'  The only place +I users show up is in server and channel loading.
' -Added chanmode +O - ops and above only
' -Fixed JoinC a little to make less retarded.
' -Fixed an endless loop in JoinC if mode +iO set :O whoops...
' -Added a message on channel join.
' -Fixed client rightclick
' -Standardised Kick and Part messages.
' -Fixed channel modes issue.
' -Added preliminary chanmode "i" support (invite only)
' -Added user nick to end of channel topic.
' -Couple of other small bugfixes.
'12/12/2003
' -Robin REALLY can't code.
' -Made client log window always scroll to the bottom.
' -Fixed bug in USSERV:Whois that caused silent failure sometimes.
' -Fixed INI file issue :@ Man I feel stupid...
' -We have preliminary mIRC\other IRC client support.
'  Eventually, I will probably move to the normal IRC protocol to avoid duplication.
' -Then again, do I want IRC support? Nah. I'll finish the program first.
'  Sorry guys. You can connect, then get told to bugger off! :P
' -Fixed channel talking (got broke when we modularised the function)
'  it was a small fix, but couldn't be bothered till now :P
' -Finished CHSERV:KickU - Can kick user from chan with a message!
' -Kick message now sent to clients as well!
'4/12/2003
' -CHSERV:ListC[Updated.]
' -CHSERV:Topic[Added and modularised. Allows changing of chan topic.]
'3/12/2003
' -Renamed CHSERV:ExitC command CHSERV:PartC.
' -CHSERV:PartC sends PARTC to client telling that they have left a chan.
' -Some modification of the type structures.
' -CHSERV:PartC fixed.
'2/12/2003
' -CHSERV:JoinC[Modularised]
' -CHSERV:PartC[Modularised]
' -CHSERV:PartC[Added. Allows user to part a chan.]
' -Fixed some variables to make them fit in with the overall
'  application structure.
' -Began tracking status of commands (i.e. not tested, etc)
' -Most of current focus is on ChanServ. No, the other services are not being
'  neglected, its just that ChanServ is VITAL for the purpose of nRC
'  (i.e. talking...) When I have free time, the other services will be seen to.
'30/11/2003
' -USSERV:Whois[Implemented mode W (lets user see when they get whois'd. IRCop Only!)]
' -Went a while with no work done... Been busy working on my webdesign business ;)
'19/11/2003
' -OPSERV:Oline[Final fix. Yes, it actually works now.]
' -CHSERV:ListC[+s implemented. Chans with +s not listed. Operoverride?]
' -Idea for +U\+q concieved in FINAL form - Began implementation.
' -intMaxUsers is tracked correctly throughout server operation.
'18/11/2003
' -OPSERV:Oline[:'( O:Block\OPER fix. Still buggered, however...]
' -USSERV:Whois[Fix\massive upgrade.]
' -USSERV:Whois[Initial +BI support.]
' -CHSERV:JoinC[Added. Allows user to join a chan.]
' -YAYYAYYAYYAYYAYYAY!!!!!!!!!!!!!!!!!!!! We can talk on channels now!
' -Robin can't code.
' -Server should no longer screw up the sending and recieving of messages...
' -I love DoEvents ;P
' -Fixed the crappy client DC code, so now users can connect after a single client dc ;)
'   YAY!

'/*/*/*/*/*/*/*/*
'I had all the previous changes logged, then the damn disk crashed... dOH!
'*/*/*/*/*/*/*/*/


'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'GENERAL NOTES
'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'If you read the code, you will notice a BIG difference between IRC and nRC:
'Here, we dont have any IRC & Services. The Services are the IRC as such-----
'All commands for the server (/whois) are actually shortcut pointers to
'services commands.

'Currently, this has a large amount of arrays and types containing arrays
'used in its construction and operation. I really cant think of another way
'to do it at the moment, but I REALLY dont like nesting arrays in type statements
'(see basGlobalTypes) :S It is REALLY annoying to try and manipulate!
'Perhaps a furthuring of basFileIO support?

'Services command. Send request to Services Command Module for
'processing. Once processed, will be sent to appropriate service module.
'This is designed this way so new services modules can be "plugged" in
'at will rather than having a hardcoded command base.

'Original UNREAL had O:Lines. Then it changed to Oper Blocks. We have the best of
'both worlds! INI Files! Yay! The file "olines.db" contains our
'"O:Blocks" Easy to use, yet still technical sounding! What a selling point!

'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'ToDo - Things to be done ASAP (aka secondary wishlist) [in chronological order]
'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
' -Channel invites (We have +i, but is rendered useless by lack of invites!)
' -AVOID NICK COLLISIONS!!!!! THIS IS VERY BAD!
' -Turn CMODE into functions... better that way.
' -Add channel bans
' -Add server bans
' -Private Messaging (Which leads to bots)

'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'Wishlist - The things I look at to amuse myself when I have nothing better to do...
'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'In order of likeliness of happening anytime soon.
' -Nickname collision prevention
' -Redo ENTIRE structures thing
' -Learn to code ;)
' -Finish this damn project ;)
' -Create a set of coding standards.
' -Use the above standards.
' -Simplify the application protocol.
' -STANDARDISE the protocol.
' -Create nick\chan registration.

'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'CHANNEL MODES
'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'Implemented\Started modes
'   O Only nRCOps and above can access.
'   T Only ChanOps\+U can set topic
'   i Invite only. ChanOps & +U can override.
'Unimplemented Modes
'Rejected\Unneeded Modes

'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'USER MODES
'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'Implemented\Started modes
'    W Lets you see when people do a /whois on you
'    r Identifies client as using a registered nick.
'        [eventually when i have ns register ;) atm it signals connected user. :S useless.]
'    o Global nRC Operator
'    O Local nRC Operator
'    B Marks you as being a Bot
'    I Invisible [YAY!!!]
'    A Server Admin
'    a Services Admin
'    C Co-Admin
'    N Network Administrator
'    H Hide nRCop Status (in whois, op Only [duh...])
'    q Only +U users can kick you on ANY channel.
'    U MonitOr - (Monitor Op)Can kick +q users, and other abuse management functions.

'Unimplemented Modes
'    d Makes it so you can not receive private messages
'    k Can see all the /kill commands executed
'    g Can send & read globops and locops

'Rejected\Unneeded Modes
'    w Can listen to wallop messages
'    S Used to protect Services Daemons
'    t Says you are using a /vhost <---- all users have vhosts...
'    h Available for help (HelpOp) (Set in OperBlock)
'    G Filters out all the bad words per configuration
'    p Hides the channels you are in in a /whois reply  <--- not needed. Chans are not returned. (yet...)
'    x Gives user a hidden hostname <----- not needed. IPs only visible by locops and above.
'    s Can listen to server notices <-- server notices are sent as "globops" and are read by access >=1
'    v Receives infected DCC Send Rejection notices
