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
'------------------------------------------------------------------------------
'General Stuff
Public Const IncorrectParam = "Incorrect parameter."
Public Const InsufficientParameters = "Insufficient parameters."
Public Const UnknownCommand = "Unknown command."
Public Const UserDoesntExist = "This user doesn't exist."
Public Const InsufficientPermissions = "Insufficient permissions."
Public Const MustBeOpered = "You must be opered to use this service. [+o]"
Public Const MustBeAServiceAdmin = "You must be opered to use this service. [+a]"
Public Const MustBeAServicesMasterOrComaster = "You must be a services master or comaster."
Public Const ServiceRestrictedToAbuseTeam = "This service is restricted to abuse team members only."
Public Const CommandRestrictedToAbuseTeam = "This command is restricted to abuse team members only."
Public Const ServiceFloodWarning = "---4WARNING--- You are flooding services. Please slow down."
Public Const ServiceFloodKill = "You were warned. Please do not flood services with requests."
Public Const ServicesConnectedToNetwork = "Services is now connected, and has been synched with the network."
Public Const ServicesTerminatingNormally = "Services are shutting down normally :) Have a nice day!"

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
 'Replace() %n with sub\function name eg KillUser
Public Const SanityCheckInvalidIndex = "SANITY CHECK! Invalid index passed to %n"
'Replace %c with the mode change (eg -k or +o)
Public Const SanityCheckParamlessModeChange = "SANITY CHECK! Channel mode change %c requires a parameter but none was given! Are the channel modes (set in basMain) not set to match your IRCd?"
'Same here (eg +x or -U)
Public Const SanityCheckUnknownModeChange = "SANITY CHECK! Channel mode change %c is unknown to us! Are the channel modes (set in basMain) not set to match your IRCd?"

'KILL Reasons
Public Const KillReasonKilledService = "Do *NOT* /kill services!"
Public Const KillReasonPasswordLimit = "Too many bad password attempts."
 'Replace() %n with GHOST user (could use n!u@h here?)
Public Const KillReasonGhostKill = "GHOST Command used by %n."
Public Const KillReasonFlooding = "Please do not flood services!"
 'Replace() %n with OperServ/whateverServ KILL user (n!u@h format?), and %r with KILL reason.
Public Const KillReasonOperServ = "Requested (%n (%r))"

'NickServ
Public Const NickServCommunicationNotice = "Services will now communicate via NOTICE"
Public Const NickServCommunicationPrivmsg = "Services will now communicate via PRIVMSG"
Public Const NickServNickAlreadyRegistered = "This nickname has already been registered. Please try another."
Public Const NickServNickRegistered = "This nickname has been registered with NickServ. If it is yours, use /msg nickserv identify <pass>, otherwise please choose another nickname."
 'SVSNICK anyone? - aquanight Use these 3 for SET ENFORCE ON (normal)
Public Const NickServEnforceIn60 = "Your nick will be changed in 60 seconds if you do not comply."
Public Const NickServEnforceIn40 = "This nickname is registered. You have 40 seconds to identify or choose a different nick, or I will change your nick."
Public Const NickServEnforceIn20 = "Final warning - you have 20 seconds to identify or choose a different nick. If you do not, your nickname will be changed."
 'Use this for SET KILL/ENFORCE QUICK - aquanight
Public Const NickServEnforceQuick = "Your nick will be changed in 20 seconds if you do not comply."
 'Use this for SET KILL/ENFORCE IMMED if you implement it -aquanight
Public Const NickServEnforceImmed = "This nickname is registered and protected. You may not use it."
 'Use this when using SVSNICK. Replace() %n with the target nick (Guest???????) - aquanight
Public Const NickServEnforcingNick = "Your nick has been changed to %n."
Public Const NickServIdentificationSuccessful = "Identification sucessful, you are now identified."
Public Const NickServIdentificationBadPassword = "Your password is incorrect."
Public Const NickServIdentificationNotRegistered = "Your nickname is not registered."
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
Public Const RootServNeedPermissions = "You do not have sufficent access to use RootServ"
Public Const RootServInjectNeedPermissions = "You do not have sufficent access to use RootServ Inject"

'AdminServ
Public Const AdminServCantAddCoMaster = "Only Masters can add comasters!"
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
Public Const ChanServChannelNotRegistered = "Channel %n has not been registered"
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
 '%c = Channel name. %n = AKICK setter. %r = Reason.
 'Theoretically, we could send a 474 too :P
 ':services.* 474 Lamer #blah :Cannot join channel (+b)
Public Const ChanServAKICKTemp = "User has been banned from %c. (%n: %r)"
 'And for perm AKICKs.
Public Const ChanServAKICKPerm = "User has been permanently banned from %c. (%n: %r)"
 'When a non-oper joins a channel MLOCK'd +O or a
 'non-admin joins a channel MLOCK'd +A.
 '(We could theoretically send a 481 too :P )
 ':services.* 481 Lamer :Permission denied - you are not an IRC Operator.
Public Const ChanServKickNotOper = "You are not permitted to enter this channel."
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
Public Const ChanServKickMLOCKi = "This channel requires an invitiation to join. Please wait for a Channel Operator to join the channel and invite you."
 'And of course for SUSPENDed channels :)
Public Const ChanServKickSuspend = "This channel is suspended."
 'And for FORBIDden channels :P
Public Const ChanServKickForbid = "This channel is forbidden."
