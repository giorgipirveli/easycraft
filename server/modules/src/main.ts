// EasyCraft server logic for Nakama's TypeScript runtime (spec §7.1, §7.4, §17; plan M4 Wave 1).
//
// Layout: src/rules/ holds pure rules (no Nakama calls, tested in Node), src/server/ the glue that
// reads and writes Nakama (tested against a fake Nakama in Node, and against a real server by
// test/integration/). This file registers the RPCs and hooks. server/README.md lists them.
//
// Nakama's JavaScript runtime is ES5 and finds registered functions by their global names, so
// every function passed to the initializer is a top-level function declaration (never a lambda
// or a variable), and the build is one plain script (tsc outFile), not a bundle.

const MODULE_NAME = "easycraft";
const MODULE_VERSION = "0.2.20"; // 0.2.20: owner #99 and #105: the account's password (password, sign_in_with_password: one device at a time; delete_account needs it), the move by code (move_request, move_approve) shipped OFF (MoveRules.ENABLED); docs/devlog/parts/accounts-99.md; // 0.2.19: the gold-double bug's leftovers (redeem_code says what the server paid; wallet_award's seq and late batches, get_account_state's hosted; docs/devlog/parts/gold-double.md); // 0.2.18: better together (owner #81/#82/#85: social_info, social_learned, social_moment, social_cheer, present_send, present_open, present_thank, study_buddy, crew; docs/devlog/parts/daily-and-friends.md); // 0.2.17: the Theater's channel list on the server (theater_channels, theater_set_channels; owner #89); // 0.2.16: the invite program (owner #79: invite_info, invite_use, invite_progress, invite_group; docs/devlog/parts/earn-invite.md); // 0.2.15: builds may hold block ids 512-1023 (cosmos: Titan's page 29; the items' 400-511 never); // 0.2.14: profiles up to 1 MiB and 5000 keys an object (the School grows, owner #70/#71); // 0.2.13: no age rules (AccountRules.ageRules off, the owner 2026-09-29); // 0.2.1: M4 E (chat); 0.2.2: M4 F (approvals, codes offline, host wallets);
// 0.2.3: M4 G (account deletion, retention clean-up, reported-message snapshots);
// 0.2.4: M4 I (blueprint gifts, showcases and guestbooks, bottle mail, build reports);
// 0.2.5: owner #45b (builds may hold block ids up to 399: the wild meadows' page 13);
// 0.2.6: M4 ghost races (share_ghost, list_ghosts; ghosts in gifts and reports)
// 0.2.7: owner #36 (the Cube Hero costume's code in the code table)
// 0.2.8: M4 Task 10 review (the band only gets stricter; DMs and rejoins end with the friendship; team chat
// only from a player in the match; groups
// and friend imports off; nothing opens while offline-only; hidden children are nobody by name; old
// notifications go after 30 days)
// 0.2.9: remove_guest (the host takes a player out of its world: the M4 Task 10 review's finding A)
// 0.2.10: the M4 Task 10 review's leftovers (a guest's spends a host reports are limited per hour: spend_limit;
// at most 20 farm clocks per player: too_many_farms; report windows go an hour after the last report)
// 0.2.11: match_players (the host names its players and checks its relay chat and trades with the server's word, not
// a guest's own: the M4 Task 10 review's finding B)
// 0.2.12: owner #67 (the account on every device: account_key, sign_in_with_key; the profile backup cleaned on
// every write: no gold, one object, the account's own name and band)

// The game calls this after signing in: proof that the server and this module are running.
function rpcHealthcheck(ctx: nkruntime.Context, _logger: nkruntime.Logger, _nk: nkruntime.Nakama, _payload: string): string {
  return JSON.stringify({
    ok: true,
    module: MODULE_NAME,
    version: MODULE_VERSION,
    server_time_ms: Server.nowMs(),
    user_id: ctx.userId || "",
  });
}

let InitModule: nkruntime.InitModule = function (ctx: nkruntime.Context, logger: nkruntime.Logger,
    nk: nkruntime.Nakama, initializer: nkruntime.Initializer) {
  initializer.registerRpc("healthcheck", rpcHealthcheck);
  // Accounts, parent settings and consent (spec §17.1-17.2).
  initializer.registerRpc("claim_username", rpcClaimUsername);
  initializer.registerRpc("get_account_state", rpcGetAccountState);
  initializer.registerRpc("set_parent_settings", rpcSetParentSettings);
  initializer.registerRpc("consent_start", rpcConsentStart);
  initializer.registerRpc("consent_status", rpcConsentStatus);
  initializer.registerBeforeUpdateAccount(beforeUpdateAccount);
  initializer.registerBeforeAuthenticateDevice(beforeAuthenticateDevice);   // owner #105: refuse a new account for a removed id
  initializer.registerBeforeAuthenticateCustom(beforeAuthenticateUsername);
  initializer.registerBeforeAuthenticateEmail(beforeAuthenticateUsername);
  // Friends, invites, who may join a match, reports (spec §17.0, §17.3).
  initializer.registerRpc("invite_friend", rpcInviteFriend);
  initializer.registerRpc("remove_guest", rpcRemoveGuest); // 0.2.9: the host removes a player from its world
  initializer.registerRpc("match_players", rpcMatchPlayers); // 0.2.11: who is in the host's match, by the server
  initializer.registerRpc("report_user", rpcReportUser);
  initializer.registerRtAfter("MatchCreate", afterMatchCreate);
  initializer.registerRtBefore("MatchJoin", rtBeforeMatchJoin);
  initializer.registerRtBefore("MatchmakerAdd", rtBeforeRefuse);
  initializer.registerRtBefore("PartyCreate", rtBeforeRefuse);
  initializer.registerBeforeAddFriends(beforeAddFriends);
  initializer.registerBeforeGetUsers(beforeGetUsers);
  // M4 Task 10 review: no groups, no friends imported past AddFriends' rules.
  initializer.registerBeforeCreateGroup(beforeRefuseSocial);
  initializer.registerBeforeImportFacebookFriends(beforeRefuseSocial);
  initializer.registerBeforeImportSteamFriends(beforeRefuseSocial);
  // Chat on Nakama channels (spec §17.4): friends' DMs and a match's team room, by the age rules.
  initializer.registerRtBefore("ChannelJoin", rtBeforeChannelJoin);
  initializer.registerRtBefore("ChannelMessageSend", rtBeforeChannelMessageSend);
  initializer.registerRtBefore("ChannelMessageUpdate", rtBeforeChannelMessageUpdate);
  // M4 G: every message is remembered for an hour, for a report about it (a snapshot of that message).
  initializer.registerRtAfter("ChannelMessageSend", rtAfterChannelMessageSend);
  // Server-side codes, the farm clock and the Survivor gold wallet (spec §17.6, plan Task 8).
  initializer.registerRpc("redeem_code", rpcRedeemCode);
  initializer.registerRpc("farm_collect", rpcFarmCollect);
  initializer.registerRpc("wallet_award", rpcWalletAward);
  // Parent controls: a grown-up approves an under-13 player's friends (M4 Wave 2, agent F).
  initializer.registerRpc("approve_friend", rpcApproveFriend);
  initializer.registerRpc("get_gold_of", rpcGetGoldOf);
  // A game writes only its own profile backup (every other collection is the server's).
  initializer.registerBeforeWriteStorageObjects(beforeWriteStorageObjects);
  initializer.registerBeforeDeleteStorageObjects(beforeDeleteStorageObjects);
  // Data rights and retention (M4 Task 8b, agent G): delete an online account (two calls), and
  // Nakama's own DeleteAccount refused (it would skip the clean-up).
  initializer.registerRpc("delete_account", rpcDeleteAccount);
  initializer.registerBeforeDeleteAccount(beforeDeleteAccount);
  // The retention clean-up: every sign-in is recorded (13 months without one deletes the account)
  // and the first sign-in of a day runs the clean-up; the owner can run it with retention_run.
  initializer.registerAfterAuthenticateDevice(afterAuthenticateDevice);
  initializer.registerRpc("retention_run", rpcRetentionRun);
  // Friends when they are not online together (M4 Wave 3, agent I): blueprint gifts, showcase visits
  // with guestbook stickers, bottle mail, and a report about a build (a copy kept for the reviewer).
  initializer.registerRpc("send_gift", rpcSendGift);
  initializer.registerRpc("list_gifts", rpcListGifts);
  initializer.registerRpc("open_gift", rpcOpenGift);
  initializer.registerRpc("publish_showcase", rpcPublishShowcase);
  initializer.registerRpc("get_showcase", rpcGetShowcase);
  initializer.registerRpc("sign_guestbook", rpcSignGuestbook);
  initializer.registerRpc("remove_sticker", rpcRemoveSticker);
  initializer.registerRpc("send_bottle", rpcSendBottle);
  initializer.registerRpc("list_bottles", rpcListBottles);
  initializer.registerRpc("open_bottle", rpcOpenBottle);
  initializer.registerRpc("report_build", rpcReportBuild);
  // Ghost races on friends' courses (M4): a best run shared on the showcase or with a gift, raced by friends.
  initializer.registerRpc("share_ghost", rpcShareGhost);
  initializer.registerRpc("list_ghosts", rpcListGhosts);
  // Owner #67: the account on every device (a sign-in key links a new phone or browser to the account).
  initializer.registerRpc("account_key", rpcAccountKey);
  initializer.registerRpc("sign_in_with_key", rpcSignInWithKey);
  // 0.2.20, owner #99: the same name on a new device, with proof and never by the name alone (a 6-digit code from the
  // new device typed on one of the account's own devices; then a one-time key for sign_in_with_key).
  initializer.registerRpc("move_request", rpcMoveRequest);
  initializer.registerRpc("move_approve", rpcMoveApprove);
  // Owner #105 (still 0.2.20, not live yet): a password made with the name; LOG IN with the name and the password on any
  // device logs every other device of the account out (one device at a time).
  initializer.registerRpc("password", rpcPassword);
  initializer.registerRpc("sign_in_with_password", rpcSignInWithPassword);
  initializer.registerRpc("log_out", rpcLogOut);   // LOG OUT unlinks this device (the final review's simple model)
  try {
    Passwords.probeHash(nk);   // the timing-even compare's hash, at the server's real bcrypt cost, made at startup
  } catch (e) {
    logger.warn("password probe hash not made at startup: %s", Server.errorText(e));
  }
  // 0.2.16, owner #79 (spec §25.2): invite a friend. Codes, the welcome gift, rewards when the friend learns, the
  // Explorer Tree, class and family codes.
  initializer.registerRpc("invite_info", rpcInviteInfo);
  initializer.registerRpc("invite_use", rpcInviteUse);
  initializer.registerRpc("invite_progress", rpcInviteProgress);
  initializer.registerRpc("invite_group", rpcInviteGroup);
  // Owner #89: the Theater's channel list (everyone reads it; only the owner sends one).
  initializer.registerRpc("theater_channels", rpcTheaterChannels);
  initializer.registerRpc("theater_set_channels", rpcTheaterSetChannels);
  // 0.2.18, owner #81, #82, #85 (the world game plan §1-§3): better together. Friendship levels, presents a friend opens
  // in the game (one can wait on the invite code), proud moments and cheers, study buddies, crews.
  initializer.registerRpc("social_info", rpcSocialInfo);
  initializer.registerRpc("social_learned", rpcSocialLearned);
  initializer.registerRpc("social_moment", rpcSocialMoment);
  initializer.registerRpc("social_cheer", rpcSocialCheer);
  initializer.registerRpc("present_send", rpcPresentSend);
  initializer.registerRpc("present_open", rpcPresentOpen);
  initializer.registerRpc("present_thank", rpcPresentThank);
  initializer.registerRpc("study_buddy", rpcStudyBuddy);
  initializer.registerRpc("crew", rpcCrew);

  try {
    nk.sqlExec(Accounts.SQL_USERNAME_INDEX);
  } catch (e) {
    // Two accounts whose names differ only in case already exist: claim_username still checks.
    logger.warn("case-insensitive username index not made: %s", Server.errorText(e));
  }
  const provider = Consent.providerFor(ctx.env);
  const production = Util.isProduction(ctx.env);
  if (production && Util.isObject(ctx.env) &&
      (ctx.env.EASYCRAFT_CONSENT_PROVIDER === "fake" || ctx.env.EASYCRAFT_DEV_OPEN_MATCHES === "true")) {
    logger.warn("production server: the developer switches in runtime.env are ignored");
  }
  logger.info("%s module %s loaded (%s); consent provider: %s", MODULE_NAME, MODULE_VERSION,
    production ? "production" : "development", provider ? provider.name : "none");
};
// No bundler: Nakama's docs add "!InitModule && InitModule.bind(null);" only so Rollup keeps
// InitModule. If a bundler is added (for npm libraries), add that line back.
