Attribute VB_Name = "Replies"
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

'This file declares constants used to reply to stuff. If we change whats here,
'we change what the replies are. Makes it easy to port to other languages etc.
'"Languages" meaning spoken languages (better to say
'translate, not port :P ). - aquanight
'------------------------------------------------------------------------------
'General Stuff
Public Const IncorrectParam = "Incorrect parameter."
'We could also send:
':services.* 461 Lamer <cmd> :Not enough parameters
Public Const InsufficientParameters = "Insufficient parameters."
'We could also send:
':services.* 421 Lamer <cmd> :Unknown command
Public Const UnknownCommand = "Unknown command."
'%c = main command name.
Public Const UnknownSubCommand = "%c - Unknown subcommand."
'We could also send:
':services.* 401 Lamer <nick> :No such nick/channel
Public Const UserDoesntExist = "This user doesn't exist."
'We could also send:
':services.* 481 Lamer :Permission denied - Insufficient services access.
Public Const InsufficientPermissions = "Permission denied"
Public Const InsufficientPermissionsAbusive = "I SPIT AT YOU THUSLY (Permission denied)."
'We could also send:
':services.* 481 Lamer :Permission denied - You are not an IRC Operator.
Public Const MustBeOpered = "You must be opered to use this service. [+o]"
'We could also send:
':services.* 481 Lamer :Permission denied - You are not a Services Administrator.
Public Const MustBeAServiceAdmin = "You must be opered to use this service. [+a]"
'We could also send:
':services.* 481 Lamer :Permission denied - You are not a Services Master or CoMaster.
Public Const MustBeAServicesMasterOrComaster = "You must be a services master or comaster."
'We could also send:
':services.* 481 Lamer :Permission denied - You are not on the Abuse Team.
Public Const ServiceRestrictedToAbuseTeam = "This service is restricted to abuse team members only."
'We could also send:
':services.* 481 Lamer :Permission denied - You are not on the Abuse Team.
Public Const CommandRestrictedToAbuseTeam = "This command is restricted to abuse team members only."
Public Const ServiceFloodWarning = "---4WARNING--- You are flooding services. Please slow down."
Public Const ServiceFloodKill = "You were warned. Please do not flood services with requests."
Public Const ServicesConnectedToNetwork = "Services is now connected, and has been synched with the network."
Public Const UserKilledService = "User %n killed a service!"
Public Const ServicesTerminatingNormally = "Services are shutting down normally :) Have a nice day!"
Public Const ServicesTerminatingSplat = "Services have gone splat. Please restart them. :)"

Public Const GeneralUnregedNick = "Nickname " + MIRC_BOLD + "%n" + MIRC_BOLD + " is not registered."

'Config file errors.
Public Const ConfigFileDoesntExist = "winse.conf doesnt exist! We need a configuration file to start."
Public Const ConfigFileUnknownDirective = "Invalid directive in winse.conf: %n"
Public Const ConfigFileUnexpectedConfVersion = "Unexpected ConfigVer given! Cannot continue!"
Public Const ConfigFileInvalidMessageType = "Unexpected DefaultMessageType, MUST be 'N' or 'P', assuming 'N'"

'Sanity Checks - When things go badly wrong.
Public Const SanityCheckLostChannel = "SANITY CHECK! We lost a channel in the array! aaaargh!!!! Advise a restart!"
Public Const SanityCheckLostUser = "SANITY CHECK! We lost a user somewhere in the array! aaiiiiiieeee! *splat* Advise a restart!"
Public Const SanityCheckCantConnectToIRCd = "Winse was unable to establish a connection to the IRCd. Please ensure the IRCd is running?"
Public Const SanityCheckCantRecover = "Winse encountered an error from which it was unable to recover. Terminating."
Public Const SanityCheckInvalidIndex = "SANITY CHECK! Invalid index passed to %n"
Public Const SanityCheckParamlessModeChange = "SANITY CHECK! Channel mode change %c requires a parameter but none was given! Are the channel modes (set in basMain) not set to match your IRCd?"
Public Const SanityCheckUnknownModeChange = "SANITY CHECK! Channel mode change %c is unknown to us! Are the channel modes (set in basMain) not set to match your IRCd?"
Public Const SanityCheckNICKInsufficientParameters = "EEEEEK! NICK user introduction message with insufficient parameters recieved! (Lame/old IRCd?)"
Public Const SanityCheckSETHOSTInsufficientParameters = "EEEEEK! SETHOST message with insufficient parameters recieved! (Lame/old IRCd?)"""
Public Const SanityCheckTOPICInsufficientParameters = "EEEEEK! TOPIC message with insufficient parameters recieved! (Lame/old IRCd?)"
Public Const SanityCheckPARTInsufficientParameters = "EEEEEK! PART message with insufficient parameters recieved! (Lame/old IRCd?)"
Public Const SanityCheckJOINInsufficientParameters = "EEEEEK! JOIN message with insufficient parameters recieved! (Lame/old IRCd?)"
Public Const SanityCheckMODEInsufficientParameters = "EEEEEK! MODE message with insufficient parameters recieved! (Lame/old IRCd?)"
Public Const SanityCheckKILLInsufficientParameters = "EEEEEK! KILL message with insufficient parameters recieved! (Lame/old IRCd?)"
Public Const SanityCheckPRIVMSGInsufficientParameters = "EEEEEK! PRIVMSG message with insufficient parameters recieved! (Lame/old IRCd?)"
Public Const SanityCheckMODENonExistantEntity = "*SPLAT* Received MODE for non-existant user/channel %n!"
Public Const SanityCheckIRCdSentQuitForServer = "HEY YOU MR. IRCD! You send SQUIT for a server, not QUIT!"
Public Const SanityCheckNickChangeCollision = "WTF? Nick Change Collision, are we desynced?: " 'stuff goes after ": "
Public Const SanityCheckServicesNickInUse = "Nick collision with services nick! killing... "
Public Const SanityCheckDBIndexInvalid = "EEEEEK! %f called with invalid index %i (%n)"
Public Const SanityCheckUnknownServer = "Unknown server! Killing new user and squitting that server."
Public Const SanityCheckServerCollision = "Server collision on %s! Squitting..."

'KILL Reasons
Public Const KillReasonKilledService = "Do *NOT* /kill services!"
'We could also send:
':services.* 464 Lamer :Password incorrect
Public Const KillReasonPasswordLimit = "Too many bad password attempts."
 'Replace() %n with GHOST user (could use n!u@h here?)
Public Const KillReasonGhostKill = "GHOST Command used by %n."
Public Const KillReasonRecoverKill = "RECOVER Command used by %n."
Public Const KillReasonNickEnforce = "Nickname Enforcement"
Public Const KillReasonFlooding = "Please do not flood services!"
 'Replace() %n with OperServ/whateverServ KILL user (n!u@h format?), and %r with KILL reason.
Public Const KillReasonOperServ = "Requested (%n (%r))"
 'Replace() %n with AKILL adder and %r with reason.
'We could also send
':services.* 465 Lamer :You are banned from this server
'(We should only do this if we are going to manually
'autokill. If we use AKILL/GLINE/TKL + G, then we can
'still use this string for the AKILL/GLINE/TKL Reason
'field.)
Public Const KillReasonAutoKill = "AutoKilled by %n: %r"
'Ghost kill reason for accounts. Remember, when we use AuthServ, GHOST != nick enforcement - the user being
'ghosted must be identified to the same account as the sender.
Public Const KillReasonAuthServGhost = "GHOST Command on account %a used by %n."

'NickServ
Public Const NickServCommunicationNotice = "Services will now communicate via NOTICE"
Public Const NickServCommunicationPrivmsg = "Services will now communicate via PRIVMSG"
Public Const NickServNickAlreadyRegistered = "This nickname has already been registered. Please try another. (If it is your nick, type /msg NickServ identify <pass>)"
Public Const NickServNickRegistered = "This nickname has been registered with NickServ. If it is yours, use /msg nickserv identify <pass>, otherwise please choose another nickname."
 'SVSNICK anyone? - aquanight Use these 3 for SET ENFORCE ON (normal)
Public Const NickServEnforceIn60 = "Your nick will be changed in 60 seconds if you do not comply."
Public Const NickServEnforceIn60Kill = "You will be disconnected from this network in 60 seconds if you do not comply."
Public Const NickServEnforceIn40 = "You now have 40 seconds to change your nick. The nick you are currently using is registered to another user."
'DALnet seems to also send RPL_NICKNAMEINUSE nick :This nickname is registered. or something like it.
Public Const NickServEnforceIn20 = "You now have 20 seconds to change your nick. If you do not comply, I will change your nick for you. This is your final warning."
Public Const NickServEnforceIn20Kill = "You now have 20 seconds to change your nick. If you do not comply, I will disconnect you from the network. This is your final warning."
 'Use this for SET KILL/ENFORCE QUICK - aquanight
Public Const NickServEnforceQuick = "Your nick will be changed in 20 seconds if you do not comply."
Public Const NickServEnforceQuickKill = "You will be disconnected from the network in 20 seconds if you do not comply."
 'Use this for SET KILL/ENFORCE IMMED if you implement it -aquanight
Public Const NickServEnforceImmed = "This nickname is registered and protected. You may not use it."
 'Forbidden nicks.
Public Const NickServEnforceForbid = "This nickname is forbidden. You may not use it."
 'Use this when using SVSNICK. Replace() %n with the target nick (Guest???????) - aquanight
Public Const NickServEnforcingNick = "Your nick has been changed to %n. The nick you were using is owned by another user."
Public Const NickServEnforcingNickKill = "You are now being disconnected. The nick you were using is registered to another user. Please reconnect with a different nick."
Public Const NickServIdentificationSuccessful = "Password accepted, you are now identified."
Public Const NickServIdentificationBadPassword = "Your password is incorrect."
Public Const NickServIdentificationNotRegistered = "Your nickname is not registered."
Public Const NickServAlreadyIdentified = "You are already identified."
Public Const NickServNotIdentified = "You are not currently identified. You must identify to your nick to use this command."
Public Const NickServNickGhosted = "Your ghost connection under nick " + MIRC_BOLD + "%n" + MIRC_BOLD + " has been terminated."
Public Const NickServNickRecover = "The user using your nick " + MIRC_BOLD + "%n" + MIRC_BOLD + " has had his nick forcibly changed to %g."
Public Const NickServNickNotInUse = "No user is using nick " + MIRC_BOLD + "%n" + MIRC_BOLD + "."
Public Const NickServGhostNickHeld = "Nick " + MIRC_BOLD + "%n" + MIRC_BOLD + " is being held by services. To release it, type " + MIRC_BOLD + "/msg NickServ RELEASE %n " + MIRC_UNDERLINE + "password" + MIRC_UNDERLINE + MIRC_BOLD + "."
Public Const NickServNickRecoverKill = "Ths user using your nick " + MIRC_BOLD + "%n" + MIRC_BOLD + " has been forcibly disconnected."
Public Const NickServRecoverRelease = "Your nick will be held unusable by services for 1 minute to prevent the user using it from retaking it immediately. To get it back sooner, type " + MIRC_BOLD + "/msg NickServ RELEASE %n " + MIRC_UNDERLINE + "password" + MIRC_UNDERLINE + MIRC_BOLD + "."
Public Const NickServNickRelease = "Your nick " + MIRC_BOLD + "%n" + MIRC_BOLD + " has been released."
Public Const NickServRelaseNotHeld = "Nick " + MIRC_BOLD + "%n" + MIRC_BOLD + " is not being held."

'AuthServ replies. I will try to reuse the NickServ replies where possible, but these are the ones for which
'that is not possible.
'Replace %a with the account name for these two.
Public Const AuthServAccountRegistered = "The account name you requested is already registered. If it is yours, type " + MIRC_BOLD + "/msg AuthServ IDENTIFY %a " + MIRC_UNDERLINE + "password" + MIRC_UNDERLINE + MIRC_BOLD + ". Other, choose a different name."
Public Const AuthServNotRegistered = "No such account " + MIRC_BOLD + "%a" + MIRC_BOLD + "."
Public Const AuthServNotIdentified = "You are not identified to an account. You must identify to an account for this command to be useful."
Public Const AuthServIdentifyNoHost = "No access for your host. If this is your account, please ask an IRCop to add your hostmask %u to this account."
Public Const AuthServIdentifyAutoHost = "Password accepted. Your hostmask %u has automatically been added to your account."

'Might this be a good idea? - aquanight
    'Indeed. --w00t
Public Const NickServTooManyBadPasswords = "You have tried to incorrectly identify too many times and as such are being disconnected."
Public Const NickServRegisterOK = "Your nickname is now registered with password %p. When connecting in the future, type /msg NickServ IDENTIFY %p to identify to your nickname."
'Stuff to fill in NickServDB.LastQuit for non-QUIT events
'that still remove a user:
 'Replace %1 and %2 with server names.
Public Const NickServLastQuitNetsplit = "Lost in netsplit (%1 %2)."
 '%s = Server, %o = Operator, %r = Reason
Public Const NickServLastQuitLocalKill = "[%s] Local kill by %o (%r)"
 '%o = Operator, %r = Reason
Public Const NickServLastQuitFarKill = "Killed (%o (%r))"

'RootServ
'We could also send:
':services.* 481 Lamer :Permission denied - Insufficient services access.
Public Const RootServNeedPermissions = "You do not have sufficent access to use RootServ"
'We could also send:
':services.* 481 Lamer :Permission denied - Insufficient services access.
Public Const RootServInjectNeedPermissions = "You do not have sufficent access to use RootServ Inject"
'We could also send:
':services.* 481 Lamer :Permission denied - Insufficient services access.
Public Const RootServSuperInjectNeedPermissions = "You do not have sufficent access to use RootServ Inject to Oper Services"
Public Const RootServSuperInjectDisabled = "RootServ Inject to Oper Services is disabled"
Public Const RootServAbusiveInjectDisabled = "Agent and AdminServ cannot be Injected to because Agent is for AbuseTeam only, and AdminServ controls permissions"

'AdminServ
'We could also send:
':services.* 481 Lamer :Permission denied - You need to be a Service Master.
Public Const AdminServCantAddCoMaster = "Only Masters can add comasters!"
'We could also send:
':services.* 481 Lamer :Permission denied - You need to be a Service Master.
Public Const AdminServCantModCoMaster = "Only Masters can modfiy a comaster's access!"
Public Const AdminServAccessModified = "User %n's access was modified sucessfully."
Public Const AdminServUserAddToAbuseTeam = "User %n added to the Abuse Team"
Public Const AdminServUserDelFromAbuseTeam = "User %n deleted from the Abuse Team"
Public Const AdminServJupeFishyNameCheck = "User %n tried to use AdminServ JUPE with a fishy name! They are trying to crash services!"

'Agent
Public Const AgentUserUnidentified = "User %n un-identified successfully."
Public Const AgentUserDeOpered = "User %n has had MODE -o set."

'ChanServ
'Use this when de-opping the first user, I guess? - aquanight
Public Const ChanServRegisteredChannel = "This channel has been registered with ChanServ."
Public Const ChanServChannelNotRegistered = "Channel %c has not been registered"
'Some registration replies.
'%c = Channel
Public Const ChanServREGISTEROK = "Channel %c has been registered to your nick. It is advised that you set a successor for this channel as soon as possible. See /chanserv HELP SET SUCCESSOR for more information."
Public Const ChanServAlreadyRegd = "Channel %c is already registered. Please try another."
'%s = Reason:
'   Channel is '#' which we should ignore.
'   Channel matches a No-Registration list.
'   Channel is FORBIDden or SUSPENDed.
'   Channel is a designated help channel.
'   Channel is a designated Operations channel.
'   Channel is a designated Debugging channel.
Public Const ChanServCantReg = "Channel %c may not be registered (%s)."
'We could also send:
':services.* 482 Lamer #Blah :You're not channel operator
Public Const ChanServRegNeedOps = "You must be a channel operator to register %c."
'We could also send:
':services.* 403 Lamer #Blah :No such channel
Public Const ChanServRegEmpty = "Channel %c is empty or is an invalid channel name. You must join it first before you can register it."
'(general no such channel error)
Public Const ChanServChanEmpty = "Channel %c is empty or invalid."
'Unregistered nicks can't register channels :P .
Public Const ChanServYouArentRegistered = "Your nick isn't registered, or you haven't identified yet."
'IDENTIFY responses.
Public Const ChanServIdentifyOK = "Password accepted for %c - you now have +" & CHANSERV_COFOUNDER & " access."
Public Const ChanServIdentifyBadPass = "Password incorrect."
Public Const ChanServIdentifyBadPassLimit = "You have incorrectly identified too many times. Go away."
Public Const ChanServIdentifyAlreadyIDd = "You are already identified to %c, or already have +" & CHANSERV_COFOUNDER & " access."
'I don't think banned lamers should be able to try and crack the password and get around it :) .
Public Const ChanServIdentifyBanned = "You can't identify to %c because you are banned."
'For RESTRICTED and MLOCK +AOz.
Public Const ChanServIdentifyRestricted = "You can't identify to %c because you aren't permitted to use it."
'Some more responses we could use.
 'For ChanServ KICKs. This is prefixed to the reason
 '(and possibly nickname).
Public Const ChanServKickRequested = "KICKed: "
 'For ChanServ BANs. Same as KICK.
Public Const ChanServBanRequested = "BANned: "
 'For ChanServ AKICK. This is the KICK comment used to
 'boot the user.
 'This one is for timed AKICKs. (Can we have timed
 'AKICKs?)
 '%c = Channel name. %r = Reason.
 'Theoretically, we could send a 474 too :P
 ':services.* 474 Lamer #blah :Cannot join channel (+b)
Public Const ChanServAKICKTemp = "User has been banned from %c. (%r)"
 'And for perm AKICKs.
Public Const ChanServAKICKPerm = "User has been permanently banned from %c. (%r)"
 'When a non-oper joins a channel MLOCK'd +O or a
 'non-admin joins a channel MLOCK'd +A.
 '(We could theoretically send a 481 too :P )
 ':services.* 481 Lamer :Permission denied - you are not an IRC Operator.
 'This will also be used for RESTRICTED.
Public Const ChanServKickNoJoin = "You are not permitted to enter this channel."
 'Whe a non-SSL joins an SSL channel (MLOCK'd +z).
 'We could probably also send whatever num Unreal/etc
 'uses for this.
Public Const ChanServKickNotSSL = "To join this channel, you must be using an SSL Connection."
 'One feature I had in mind is when JOINing a channel
 'that is MLOCK'd +k or +i, we should not allow such a
 'join for the first user unless he has the INVITE
 'privilege.
 '%c = Channel.
 'We could also send:
 ':services.* 475 Lamer #blah :Cannot join channel (+k)
Public Const ChanServKickMLOCKk = "This channel requires a key to join. If you know the key, type /chanserv JOIN %c key"
 'And for this, we could send
 ':services.* 473 Lamer #blah :Cannot join channel (+i)
 '(assuming the joiner doesn't have the INVITE privlege)
Public Const ChanServKickMLOCKi = "This channel requires an invitiation to join. Please wait for a Channel Operator to join the channel and invite you."
 'And of course for SUSPENDed channels :)
 'Could we use 481 (Not IRCop) here?
Public Const ChanServKickSuspend = "This channel is suspended."
 'And for FORBIDden channels :P
 'Could we use 481 (Not IRCop) here?
Public Const ChanServKickForbid = "This channel is forbidden."
 'ACCESS command replies...
Public Const ChanServACEChanged = "User %n Flags are now %f"
Public Const ChanServACENotChanged = "No changes to be made to %n"
Public Const ChanServACEFlagIgnored = "Flag %f ignored: %r"
Public Const ChanServACEIgnorePFounder = "Only one permanent founder may exist. To transfer Permanent Founder control to someone else, use " + MIRC_BOLD + "/msg ChanServ SET %c FOUNDER %n" + MIRC_BOLD
Public Const ChanServACEIgnoreAlreadySet = "The flag is already set."
Public Const ChanServACEIgnoreAlreadyUnset = "The flag is already unset."

'Now some verbosity messages.
Public Const ChanServIdentifyWALLCHOPSFailed = "*** Notice -- Failed IDENTIFY from %n (%u): %r"
Public Const ChanServVerboseACLChange = "*** Notice -- %n sets %c flags: %f [now %s]"
Public Const ChanServVerboseInvite = "*** Notice -- %n invited %c into the channel."
Public Const ChanServInvitation = "%n invites you to join %c"
Public Const ChanServUnbanExemptEntry = "You match the EXEMPT entry " + MIRC_BOLD + "%e" + MIRC_BOLD + ". The exempt shall be activated."
Public Const ChanServUnbanExemptFlag = "You have the +" + CHANSERV_EXEMPT + " flag. An exempt has been activated on your host."
Public Const ChanServUnbanBansRemoved = "%n ban(s) have been removed."
Public Const ChanServVerboseUnban = "*** Notice -- %n has unbanned %c."
Public Const ChanServNowUnbanned = "You are no longer banned from %c."

'Help System
Public Const UnknownCommandOrHelpNotAvailable = "No help available."
