// An in-memory stand-in for the parts of Nakama's runtime API the module uses (nk.*), so the RPCs
// and hooks run in Node tests. It follows Nakama 3.41's behaviour where the module depends on it:
// storage versions ("*" = only if new) and write permissions, wallets never negative, exact-case
// username lookups, friend states (0 friend, 1 invite sent, 2 invite received, 3 blocked), and the
// relayed-match stream (mode 5, subject = the match id without its "." suffix).
// The integration script (test/integration/) checks the same behaviour against a real server.
import { createHash, randomUUID } from "node:crypto";

export const SYSTEM_USER = "00000000-0000-0000-0000-000000000000";

type Json = { [key: string]: any };

interface FakeUser {
  userId: string;
  username: string;
  displayName: string;
  metadata: Json;
  wallet: { [key: string]: number };
  createTime: number;
  updateTimeMs: number; // users.update_time (M4 G: the inactive-account fallback)
}

interface FakeObject {
  collection: string;
  key: string;
  userId: string;
  value: Json;
  version: string;
  permissionRead: number;
  permissionWrite: number;
  createTime: number;
  updateTime: number;
}

export class NakamaError extends Error {
  code: number;
  constructor(message: string, code = 13) {
    super(message);
    this.code = code;
  }
}

export class FakeNakama {
  users = new Map<string, FakeUser>();
  storage = new Map<string, FakeObject>();
  notifications: Json[] = [];
  ledger: Json[] = [];
  // edges.get(a).get(b) = state of b in a's friend list
  edges = new Map<string, Map<string, number>>();
  // stream key "mode|subject|label" -> presences
  streams = new Map<string, Json[]>();
  sql: { query: string; params: any[] }[] = [];
  // The database's clock for storage times (Nakama gives them as unix seconds). M4 G: tests set it.
  clock: () => number = () => Date.now();
  private versionCounter = 0;

  addUser(username: string, metadata: Json = {}, wallet: Json = {}): string {
    const id = randomUUID();
    this.users.set(id, { userId: id, username, displayName: "", metadata: { ...metadata }, wallet: { ...wallet }, createTime: 0,
      updateTimeMs: this.clock() });
    return id;
  }

  befriend(a: string, b: string, state = 0): void {
    this.edge(a).set(b, state);
    this.edge(b).set(a, state === 1 ? 2 : state === 2 ? 1 : state);
  }

  private edge(a: string): Map<string, number> {
    if (!this.edges.has(a)) {
      this.edges.set(a, new Map());
    }
    return this.edges.get(a)!;
  }

  // A relayed match: its id is "<uuid>." and its presences live on stream mode 5.
  createMatch(hostId: string): string {
    const uuid = randomUUID();
    this.streams.set("5|" + uuid + "|", [this.presence(hostId)]);
    return uuid + ".";
  }

  joinMatch(matchId: string, userId: string): void {
    this.streams.get("5|" + matchId.split(".")[0] + "|")!.push(this.presence(userId));
  }

  leaveMatch(matchId: string, userId: string): void {
    const key = "5|" + matchId.split(".")[0] + "|";
    this.streams.set(key, (this.streams.get(key) || []).filter((p) => p.userId !== userId));
  }

  presence(userId: string): Json {
    return { userId, sessionId: randomUUID(), username: this.users.get(userId)?.username || "", nodeId: "nakama" };
  }

  object(collection: string, key: string, userId: string): FakeObject | undefined {
    return this.storage.get(collection + "|" + key + "|" + userId);
  }

  // --- nk.* ---

  accountGetId(userId: string): Json {
    const u = this.users.get(userId);
    if (!u) {
      throw new NakamaError("account not found", 5);
    }
    return {
      user: { userId: u.userId, username: u.username, displayName: u.displayName, metadata: structuredClone(u.metadata),
        createTime: u.createTime, online: false },
      wallet: { ...u.wallet },
      devices: [...this.devices].filter(([, owner]) => owner === userId).map(([id]) => ({ id })),
    };
  }

  // Owner #67: device ids (Nakama's user_device) and linking. An id belongs to one account at most.
  devices = new Map<string, string>(); // device id -> user id
  loggedOut: string[] = []; // sessionLogout(userId) calls

  deviceOwner(deviceId: string): string | undefined {
    return this.devices.get(deviceId);
  }

  linkDevice(userId: string, deviceId: string): void {
    if (!this.users.has(userId)) {
      throw new NakamaError("account not found", 5);
    }
    const owner = this.devices.get(deviceId);
    if (owner !== undefined && owner !== userId) {
      throw new NakamaError("Device ID already in use.", 6);
    }
    this.devices.set(deviceId, userId);
  }

  unlinkDevice(userId: string, deviceId: string): void {
    if (this.devices.get(deviceId) !== userId) {
      return;
    }
    const others = [...this.devices.values()].filter((o) => o === userId).length - 1;
    if (others <= 0 && !this.customs.has(userId)) {
      // Nakama 3.41: "Cannot unlink last account identifier. Check profile exists and is not last link."
      throw new NakamaError("Cannot unlink last account identifier. Check profile exists and is not last link.", 7);
    }
    this.devices.delete(deviceId);
  }

  // Owner #105: a custom id (LOG OUT links a random one nobody holds, so the account's last device can be unlinked).
  customs = new Map<string, string>(); // user id -> custom id
  linkCustom(userId: string, customId: string): void {
    if (!this.users.has(userId)) {
      throw new NakamaError("account not found", 5);
    }
    this.customs.set(userId, customId);
  }

  sessionLogout(userId: string): void {
    this.loggedOut.push(userId);
  }

  disconnected: string[] = []; // sessionDisconnect(sessionId) calls

  sessionDisconnect(sessionId: string): void {
    this.disconnected.push(sessionId);
  }

  accountUpdateId(userId: string, username?: string | null, displayName?: string | null, _tz?: any, _loc?: any,
      _lang?: any, _avatar?: any, metadata?: Json | null): void {
    const u = this.users.get(userId);
    if (!u) {
      throw new NakamaError("account not found", 5);
    }
    if (username) {
      for (const other of this.users.values()) {
        if (other.userId !== userId && other.username === username) {
          throw new NakamaError("Username is already in use.", 6);
        }
      }
      u.username = username;
    }
    if (displayName !== undefined && displayName !== null) {
      u.displayName = displayName;
    }
    if (metadata !== undefined && metadata !== null) {
      u.metadata = structuredClone(metadata);
    }
  }

  usersGetId(ids: string[]): Json[] {
    return ids.filter((id) => this.users.has(id)).map((id) => this.accountGetId(id).user);
  }

  usersGetUsername(names: string[]): Json[] {
    const out: Json[] = [];
    for (const u of this.users.values()) {
      if (names.includes(u.username)) {
        out.push(this.accountGetId(u.userId).user);
      }
    }
    return out;
  }

  storageRead(keys: Json[]): Json[] {
    const out: Json[] = [];
    for (const k of keys) {
      const o = this.object(k.collection, k.key, k.userId || SYSTEM_USER);
      if (o) {
        out.push(structuredClone(o));
      }
    }
    return out;
  }

  storageWrite(writes: Json[]): Json[] {
    for (const w of writes) {
      const existing = this.object(w.collection, w.key, w.userId || SYSTEM_USER);
      if (w.version === "*" && existing) {
        throw new NakamaError("Storage write rejected - version check failed.", 3);
      }
      if (w.version && w.version !== "*" && (!existing || existing.version !== w.version)) {
        throw new NakamaError("Storage write rejected - version check failed.", 3);
      }
    }
    const acks: Json[] = [];
    for (const w of writes) {
      const userId = w.userId || SYSTEM_USER;
      const existing = this.object(w.collection, w.key, userId);
      const o: FakeObject = {
        collection: w.collection, key: w.key, userId, value: structuredClone(w.value),
        version: "v" + ++this.versionCounter,
        permissionRead: w.permissionRead === undefined ? 1 : w.permissionRead,
        permissionWrite: w.permissionWrite === undefined ? 1 : w.permissionWrite,
        createTime: existing ? existing.createTime : this.seconds(), updateTime: this.seconds(),
      };
      this.storage.set(w.collection + "|" + w.key + "|" + userId, o);
      acks.push({ collection: o.collection, key: o.key, userId, version: o.version });
    }
    return acks;
  }

  storageDelete(keys: Json[]): void {
    for (const k of keys) {
      const existing = this.object(k.collection, k.key, k.userId || SYSTEM_USER);
      if (k.version && (!existing || existing.version !== k.version)) {
        throw new NakamaError("Storage delete rejected - version check failed.", 3);
      }
    }
    for (const k of keys) {
      this.storage.delete(k.collection + "|" + k.key + "|" + (k.userId || SYSTEM_USER));
    }
  }

  walletUpdate(userId: string, changeset: Json, metadata: Json = {}, updateLedger = false): Json {
    const u = this.users.get(userId);
    if (!u) {
      throw new NakamaError("account not found", 5);
    }
    const previous = { ...u.wallet };
    const next = { ...u.wallet };
    for (const k of Object.keys(changeset)) {
      next[k] = (next[k] || 0) + changeset[k];
      if (next[k] < 0) {
        throw new NakamaError("wallet update rejected: negative value", 3);
      }
    }
    u.wallet = next;
    if (updateLedger) {
      this.ledger.push({ userId, changeset: { ...changeset }, metadata: structuredClone(metadata) });
    }
    return { userId, previous, updated: { ...next } };
  }

  notificationSend(userId: string, subject: string, content: Json, code: number, senderId?: string | null, persistent?: boolean): void {
    this.notifications.push({ id: randomUUID(), userId, subject, content: structuredClone(content), code,
      senderId: senderId || SYSTEM_USER, persistent: !!persistent, createTimeMs: this.clock() });
  }

  friendsList(userId: string, limit = 100, state?: number, _cursor?: string): Json {
    const friends: Json[] = [];
    for (const [other, s] of this.edge(userId)) {
      if (state === undefined || state === null || s === state) {
        friends.push({ user: this.accountGetId(other).user, state: s, updateTime: 0 });
      }
    }
    return { friends: friends.slice(0, limit), cursor: "" };
  }

  // Nakama's friendsAdd as the runtime does it (M4 Wave 2, agent F): accepting when they asked,
  // else a request (theirs shows 2); nothing for friends or when they blocked this user.
  friendsAdd(userId: string, _username: string, ids: string[], _usernames: string[] = [], _metadata: Json = {}): Json {
    for (const other of ids) {
      const mine = this.edge(userId).get(other);
      const theirs = this.edge(other).get(userId);
      if (mine === 0 || theirs === 3) {
        continue;
      }
      if (theirs === 1) {
        this.befriend(userId, other, 0);
      } else {
        this.befriend(userId, other, 1);
      }
    }
    return this.friendsList(userId);
  }

  friendsDelete(userId: string, _username: string, ids: string[], _usernames: string[] = []): Json {
    for (const other of ids) {
      this.edge(userId).delete(other);
      this.edge(other).delete(userId);
    }
    return this.friendsList(userId);
  }

  streamUserList(stream: Json): Json[] {
    return structuredClone(this.streams.get(stream.mode + "|" + (stream.subject || "") + "|" + (stream.label || "")) || []);
  }

  // Kicks one presence off a stream (the relayed match's guest removed by its host). Tests read `kicks`.
  kicks: Json[] = [];
  streamUserKick(presence: Json, stream: Json): void {
    const key = stream.mode + "|" + (stream.subject || "") + "|" + (stream.label || "");
    this.kicks.push({ userId: presence.userId, sessionId: presence.sessionId, stream: structuredClone(stream) });
    this.streams.set(key, (this.streams.get(key) || []).filter((p) => p.sessionId !== presence.sessionId));
  }

  streamCount(stream: Json): number {
    return this.streamUserList(stream).length;
  }

  sqlQuery(query: string, params: any[] = []): Json[] {
    this.sql.push({ query, params });
    const g = this.sqlQueryG(query, params);
    if (g !== null) {
      return g;
    }
    const i = this.sqlQueryI(query, params);
    if (i !== null) {
      return i;
    }
    if (query.includes("lower(username)")) {
      const out: Json[] = [];
      for (const u of this.users.values()) {
        if (u.username.toLowerCase() === params[0] && u.userId !== params[1]) {
          out.push({ id: u.userId });
        }
      }
      return out;
    }
    throw new NakamaError("fake sqlQuery doesn't know: " + query);
  }

  sqlExec(query: string, params: any[] = []): Json {
    this.sql.push({ query, params });
    return { rowsAffected: this.sqlExecG(query, params) + this.sqlExecI(query, params) };
  }

  // --- chat channels (M4 Wave 2, agent E): ids as Nakama builds them, kept messages oldest first ---
  channelMessages = new Map<string, Json[]>();

  channelIdBuild(sender: string, target: string, chanType: number): string {
    if (chanType === 2) {
      return "4." + [sender, target].sort().join(".") + ".";
    }
    return chanType === 1 ? "2..." + target : "3." + target + "..";
  }

  addChannelMessage(channelId: string, senderId: string, username: string, createTimeSec: number): string {
    const id = randomUUID();
    if (!this.channelMessages.has(channelId)) {
      this.channelMessages.set(channelId, []);
    }
    this.channelMessages.get(channelId)!.push({ channelId, messageId: id, code: 0, senderId, username,
      content: '{"text":"hi"}', createTime: createTimeSec, updateTime: createTimeSec, persistent: true });
    this.channelMessages.get(channelId)!.sort((x, y) => x.createTime - y.createTime);
    return id;
  }

  channelMessagesList(channelId: string, limit = 100, forward = true, _cursor?: string): Json {
    const all = [...(this.channelMessages.get(channelId) || [])];
    if (!forward) {
      all.reverse();
    }
    return { messages: structuredClone(all.slice(0, limit)) };
  }

  channelMessageRemove(channelId: string, messageId: string, _senderId?: string, _username?: string, _persist = true): Json {
    const list = this.channelMessages.get(channelId) || [];
    const i = list.findIndex((m) => m.messageId === messageId);
    if (i < 0) {
      throw new NakamaError("message not found", 5);
    }
    list.splice(i, 1);
    return { channelId, messageId };
  }

  sha256Hash(text: string): string {
    return createHash("sha256").update(text, "utf8").digest("hex");
  }

  // bcrypt as Nakama has it (bcryptHash/bcryptCompare): a salted hash that carries its salt; a fake with the same shape.
  bcryptHash(text: string): string {
    const salt = createHash("sha256").update(String(Math.random())).digest("hex").slice(0, 22);
    return "$2a$10$" + salt + createHash("sha256").update(salt + text, "utf8").digest("hex");
  }

  bcryptCompare(hash: string, text: string): boolean {
    const salt = hash.slice(7, 29);
    return hash === "$2a$10$" + salt + createHash("sha256").update(salt + text, "utf8").digest("hex");
  }

  // --- M4 Task 8b, agent G: account deletion, retention, the recent-message cache ---
  // accountDeleteId does what Nakama 3.41's database does on "DELETE FROM users" (checked on a real
  // server: ON DELETE CASCADE from users to user_device, user_edge (both ends), storage,
  // wallet_ledger, notification (to the user) and message (sent by the user); notifications the user
  // SENT and the other side of a DM stay). The SQL the module runs is recognised by its text.
  deleted: { userId: string; recorded: boolean }[] = [];
  cascade = true; // false: accountDeleteId removes only the user (tests prove the module's own clean-up)
  cache = new Map<string, { value: any; expiresMs: number }>();

  seconds(): number {
    return Math.floor(this.clock() / 1000);
  }

  accountDeleteId(userId: string, recorded = false): void {
    if (!this.users.has(userId)) {
      throw new NakamaError("user not found", 5);
    }
    this.users.delete(userId);
    this.deleted.push({ userId, recorded });
    for (const [id, owner] of [...this.devices]) {
      if (owner === userId) {
        this.devices.delete(id); // user_device cascades whatever the switch
      }
    }
    if (!this.cascade) {
      return;
    }
    for (const [k, o] of [...this.storage]) {
      if (o.userId === userId) {
        this.storage.delete(k);
      }
    }
    this.ledger = this.ledger.filter((e) => e.userId !== userId);
    this.edges.delete(userId);
    for (const m of this.edges.values()) {
      m.delete(userId);
    }
    this.notifications = this.notifications.filter((n) => n.userId !== userId);
    for (const [id, list] of this.channelMessages) {
      this.channelMessages.set(id, list.filter((m) => m.senderId !== userId));
    }
  }

  // Objects of one owner (or every owner with null) in a collection, by key; cursor = the next index.
  storageList(userId: string | null | undefined, collection: string, limit = 100, cursor?: string): Json {
    const all = [...this.storage.values()]
      .filter((o) => o.collection === collection && (userId === null || userId === undefined || o.userId === userId))
      .sort((a, b) => (a.key + a.userId < b.key + b.userId ? -1 : 1));
    const start = cursor ? Number(cursor) : 0;
    const page = all.slice(start, start + limit);
    return { objects: structuredClone(page), cursor: start + limit < all.length ? String(start + limit) : "" };
  }

  uuidv4(): string {
    return randomUUID();
  }

  localcacheGet(key: string): any {
    const e = this.cache.get(key);
    if (!e || (e.expiresMs > 0 && e.expiresMs <= this.clock())) {
      return null;
    }
    return e.value;
  }

  localcachePut(key: string, value: any, ttl = 0): void {
    this.cache.set(key, { value, expiresMs: ttl > 0 ? this.clock() + ttl * 1000 : 0 });
  }

  localcacheDelete(key: string): void {
    this.cache.delete(key);
  }

  private dmUsers(channelId: string): string[] {
    const p = channelId.split(".");
    return p[0] === "4" && p.length >= 3 ? [p[1], p[2]] : [];
  }

  sqlQueryG(query: string, params: any[]): Json[] | null {
    if (query.includes("key = 'friend_requests'")) {
      const wanted = JSON.parse(params[0])[0].user_id;
      const out: Json[] = [];
      for (const o of this.storage.values()) {
        if (o.collection === "parent" && o.key === "friend_requests" &&
            (o.value.requests || []).some((r: Json) => r.user_id === wanted)) {
          out.push({ id: o.userId });
        }
      }
      return out;
    }
    if (query.includes("value ->> 'reporter_id' = $1")) {
      return [...this.storage.values()]
        .filter((o) => o.collection === "reports" && o.userId === SYSTEM_USER && o.value.reporter_id === params[0])
        .map((o) => ({ key: o.key }));
    }
    if (query.includes("key = 'signed_in'")) {
      const rows: Json[] = [];
      for (const u of this.users.values()) {
        if (u.userId === SYSTEM_USER) {
          continue;
        }
        const seen = this.object("activity", "signed_in", u.userId);
        const last = seen && typeof seen.value.at_ms === "number" ? seen.value.at_ms : u.updateTimeMs;
        if (last < params[0]) {
          rows.push({ id: u.userId, last_ms: last });
        }
      }
      return rows.sort((a, b) => a.last_ms - b.last_ms).slice(0, params[1]);
    }
    return null;
  }

  sqlExecG(query: string, params: any[]): number {
    let n = 0;
    if (query.startsWith("DELETE FROM notification WHERE sender_id")) {
      const before = this.notifications.length;
      this.notifications = this.notifications.filter((x) => x.senderId !== params[0]);
      return before - this.notifications.length;
    }
    if (query.includes("FROM notification WHERE create_time <")) {   // M4 Task 10 review: old notifications
      const old = this.notifications.filter((x) => x.createTimeMs < params[0]).slice(0, params[1]);
      this.notifications = this.notifications.filter((x) => !old.includes(x));
      return old.length;
    }
    if (query.includes("key = 'report' AND update_time <")) {   // M4 Task 10 review F: old report windows
      const old = [...this.storage.values()]
        .filter((o) => o.collection === "limits" && o.key === "report" && o.updateTime * 1000 < params[0]).slice(0, params[1]);
      for (const o of old) {
        this.storage.delete(o.collection + "|" + o.key + "|" + o.userId);
      }
      return old.length;
    }
    if (query.startsWith("DELETE FROM notification n WHERE")) {
      const before = this.notifications.length;
      this.notifications = this.notifications.filter((x) => x.senderId === SYSTEM_USER || this.users.has(x.senderId));
      return before - this.notifications.length;
    }
    if (query.includes("stream_subject = $1")) {
      for (const [id, list] of this.channelMessages) {
        if (this.dmUsers(id).includes(params[0])) {
          n += list.length;
          this.channelMessages.set(id, []);
        }
      }
      return n;
    }
    if (query.includes("NOT EXISTS") && query.includes("FROM message")) {
      for (const [id, list] of this.channelMessages) {
        const two = this.dmUsers(id);
        if (two.length === 2 && two.some((u) => !this.users.has(u))) {
          n += list.length;
          this.channelMessages.set(id, []);
        }
      }
      return n;
    }
    if (query.includes("FROM message WHERE create_time <")) {
      const cutoffSec = params[0] / 1000;
      for (const [id, list] of this.channelMessages) {
        const keep: Json[] = [];
        for (const m of list) {
          if (m.createTime < cutoffSec && n < params[1]) {
            n++;
          } else {
            keep.push(m);
          }
        }
        this.channelMessages.set(id, keep);
      }
      return n;
    }
    return 0;
  }

  // --- M4 Wave 3, agent I: gifts, bottles and guestbooks (server/modules/src/server/gifts.ts's SQL) ---

  private giftsAndBottles(): FakeObject[] {
    return [...this.storage.values()].filter((o) => o.collection === "gifts" || o.collection === "bottles");
  }

  private guestbooks(): FakeObject[] {
    return [...this.storage.values()].filter((o) => o.collection === "guestbook" && o.key === "guestbook");
  }

  sqlQueryI(query: string, params: any[]): Json[] | null {
    if (query.includes("value -> 'entries' @> $1::jsonb")) {
      const wanted = JSON.parse(params[0])[0].from_id;
      return this.guestbooks().filter((o) => (o.value.entries || []).some((e: Json) => e.from_id === wanted)).map((o) => ({ id: o.userId }));
    }
    if (query.includes("(value ->> 'oldest_ms')::bigint <= $1")) {
      return this.guestbooks().filter((o) => typeof o.value.oldest_ms === "number" && o.value.oldest_ms <= params[0])
        .slice(0, params[1]).map((o) => ({ id: o.userId }));
    }
    if (query.includes("jsonb_array_elements")) {
      return this.guestbooks().filter((o) => (o.value.entries || []).some((e: Json) => !this.users.has(e.from_id)))
        .slice(0, params[0]).map((o) => ({ id: o.userId }));
    }
    return null;
  }

  sqlExecI(query: string, params: any[]): number {
    let gone: FakeObject[] = [];
    if (query.includes("value ->> 'from_id' = $1")) {
      gone = this.giftsAndBottles().filter((o) => o.value.from_id === params[0]);
    } else if (query.includes("(value ->> 'created_ms')::bigint <= $1")) {
      gone = this.giftsAndBottles().filter((o) => typeof o.value.created_ms === "number" && o.value.created_ms <= params[0])
        .slice(0, params[1]);
    } else if (query.includes("NOT EXISTS") && query.includes("collection IN ('gifts', 'bottles')")) {
      gone = this.giftsAndBottles().filter((o) => !this.users.has(o.value.from_id));
    }
    for (const o of gone) {
      this.storage.delete(o.collection + "|" + o.key + "|" + o.userId);
    }
    return gone.length;
  }
}

export class FakeLogger {
  lines: string[] = [];
  private add(level: string, format: string, args: any[]): void {
    let i = 0;
    this.lines.push(level + " " + format.replace(/%[sdvq]/g, () => String(args[i++])));
  }
  debug(format: string, ...args: any[]): void { this.add("DEBUG", format, args); }
  info(format: string, ...args: any[]): void { this.add("INFO", format, args); }
  warn(format: string, ...args: any[]): void { this.add("WARN", format, args); }
  error(format: string, ...args: any[]): void { this.add("ERROR", format, args); }
}

// A context as Nakama gives an RPC or hook called by this user.
export function ctx(userId: string, env: Json = {}, username = ""): Json {
  return { env, userId, username, sessionId: randomUUID(), executionMode: "rpc", node: "nakama", version: "test" };
}
