// Chat rules (spec §5.13, §17.4), ported from the game's core/rules/chat_rules.gd with the same
// lists and test cases (server/modules/test/chat_rules.test.ts mirrors tests/unit/test_chat_rules.gd):
// cleanup, quick phrases only for under_13, and the bad-word and personal-info filter for 13_plus
// free text. The server adds what a channel message may hold ({"text"} or {"emote"}) and the chat
// level of a channel (the strictest of its players).

namespace ChatRules {
  export const MAX_LENGTH = 120;
  export const MAX_RAW_LENGTH = 1000;
  export const QUICK_PHRASES: string[] = [
    "Hi!", "Follow me!", "Look!", "Nice build!", "Thanks!", "Help!", "Bye!",
    "Come here!", "Wow!", "Let's build!", "Good job!", "Yes!", "No!",
  ];
  export const PHONE_DIGITS = 7;
  export const PERSONAL_PHRASES: string[] = [
    "address", "street", "zip code", "postcode", "phone number", "my number", "call me", "text me",
    "email", "e mail", "gmail", "hotmail", "snapchat", "snap me", "instagram", "insta", "whatsapp",
    "discord", "telegram", "facebook", "tiktok", "kik", "password", "where do you live", "i live at",
    "i live on", "my school", "what school",
  ];
  export const STRONG_WORDS: string[] = ["fuck", "shit", "bitch", "slut", "whore", "porn"];
  // The zero of every run of ten Unicode decimal digits (category Nd, Unicode 16) besides ASCII.
  export const DIGIT_ZEROS: number[] = [
    0x660, 0x6F0, 0x7C0, 0x966, 0x9E6, 0xA66, 0xAE6, 0xB66, 0xBE6, 0xC66, 0xCE6, 0xD66,
    0xDE6, 0xE50, 0xED0, 0xF20, 0x1040, 0x1090, 0x17E0, 0x1810, 0x1946, 0x19D0, 0x1A80, 0x1A90,
    0x1B50, 0x1BB0, 0x1C40, 0x1C50, 0xA620, 0xA8D0, 0xA900, 0xA9D0, 0xA9F0, 0xAA50, 0xABF0, 0xFF10,
    0x104A0, 0x10D30, 0x10D40, 0x11066, 0x110F0, 0x11136, 0x111D0, 0x112F0, 0x11450, 0x114D0, 0x11650, 0x116C0,
    0x116D0, 0x116DA, 0x11730, 0x118E0, 0x11950, 0x11BF0, 0x11C50, 0x11D50, 0x11DA0, 0x11F50, 0x16130, 0x16A60,
    0x16AC0, 0x16B50, 0x16D70, 0x1CCF0, 0x1D7CE, 0x1D7D8, 0x1D7E2, 0x1D7EC, 0x1D7F6, 0x1E140, 0x1E2F0, 0x1E4F0,
    0x1E5F1, 0x1E950, 0x1FBF0,
  ];
  export const DIGIT_LOOKALIKES: string[] = ["⁰¹²³⁴⁵⁶⁷⁸⁹", "₀₁₂₃₄₅₆₇₈₉", "⓪①②③④⑤⑥⑦⑧⑨"];
  // In the game's order: a later entry wins for a character listed twice.
  export const CHAR_FOLDS: string[][] = [
    ["a", "àáâãäåāăąǎαа"], ["b", "βвь"], ["c", "çćĉċčсϲ"], ["d", "ďđðԁ"], ["e", "èéêëēĕėęěεеё"],
    ["g", "ĝğġģ"], ["h", "ĥħһнΗ"], ["i", "ìíîïĩīĭįıιіїɩ"], ["j", "ĵј"], ["k", "ķκк"], ["l", "ĺļľŀłӏ"],
    ["m", "мΜ"], ["n", "ñńņňŉηпΝ"], ["o", "òóôõöøōŏőοоσ"], ["p", "ρр"], ["r", "ŕŗřг"], ["s", "śŝşšșѕ"],
    ["t", "ţťŧțτт"], ["u", "ùúûüũūŭůűųυμ"], ["v", "ν"], ["w", "ŵωш"], ["x", "χх"], ["y", "ýÿŷуүΥ"], ["z", "źżž"],
    ["ss", "ß"], ["ae", "æ"], ["oe", "œ"], ["th", "þ"],
    [" ", "              　"],
    ["-", "‐‑‒–—―−﹣"],
  ];

  const PHONE_RE = /[0-9][0-9 ()+.\-]*[0-9]/g;
  const EMAIL_RE = /[^ \t\n\v\f\r]+@[^ \t\n\v\f\r]+\.[^ \t\n\v\f\r]+/;
  const LINK_RE = /(https?:\/\/|www\.|\b[a-z0-9-]+\.(com|net|org|io|gg|me|co|tv|ly|app|xyz|uk|de)\b)/i;
  const NON_WORD_RE = /[^a-z0-9]+/g;
  const NON_LETTER_RE = /[^a-z]+/g;
  const EMOTE_RE = /^[a-z0-9_]{1,32}$/;

  let foldMap: { [ch: string]: string } | null = null;

  // Control and invisible characters go (or become spaces), runs of spaces become one, the ends are
  // trimmed, and the result is at most MAX_LENGTH characters.
  export function clean(text: string): string {
    const input = Util.chars(Util.firstChars(String(text), MAX_RAW_LENGTH));
    let out = "";
    for (let i = 0; i < input.length; i++) {
      const c = Util.codePoints(input[i])[0];
      if (c < 32 || (c >= 127 && c < 160)) {
        out += " ";
      } else if (!isInvisible(c)) {
        out += input[i];
      }
    }
    // Godot's "\\s+" (PCRE2 without UCP) is ASCII whitespace, and the control characters are spaces now.
    out = Util.stripEdges(out.replace(/ {2,}/g, " "));
    return Util.stripEdges(Util.firstChars(out, MAX_LENGTH));
  }

  function isInvisible(c: number): boolean {
    return (c >= 0x200B && c <= 0x200F) || (c >= 0x202A && c <= 0x202E) || (c >= 0x2060 && c <= 0x2069) ||
      c === 0xFEFF || c === 0x00AD;
  }

  export function isQuickPhrase(text: string): boolean {
    return QUICK_PHRASES.indexOf(text) >= 0;
  }

  // Checks a message from a player of `band`: {text: cleaned} or {error: empty | quick_chat_only |
  // personal_info | blocked_word}.
  export function check(text: string, band: string): { text?: string; error?: string } {
    const t = clean(text);
    if (t === "") {
      return { error: "empty" };
    }
    if (isQuickPhrase(t)) {
      return { text: t };
    }
    if (AccountRules.effectiveBand(band) !== AccountRules.TEEN_PLUS) {
      return { error: "quick_chat_only" };
    }
    const code = filterCode(t);
    return code !== "" ? { error: code } : { text: t };
  }

  export function canReceive(text: string, band: string): boolean {
    return AccountRules.effectiveBand(band) === AccountRules.TEEN_PLUS || isQuickPhrase(text);
  }

  // "" when the text is fine, else personal_info or blocked_word.
  export function filterCode(raw: string): string {
    const text = normalize(raw);
    const phones = text.match(PHONE_RE) || [];
    for (let i = 0; i < phones.length; i++) {
      if (phones[i].replace(/[^0-9]/g, "").length >= PHONE_DIGITS) {
        return "personal_info";
      }
    }
    if (EMAIL_RE.test(text) || LINK_RE.test(text)) {
      return "personal_info";
    }
    const plain = " " + Util.stripEdges(text.toLowerCase().replace(NON_WORD_RE, " ")) + " ";
    for (let i = 0; i < PERSONAL_PHRASES.length; i++) {
      if (plain.indexOf(" " + PERSONAL_PHRASES[i] + " ") >= 0) {
        return "personal_info";
      }
    }
    const list = words(text);
    for (let w = 0; w < list.length; w++) {
      for (let b = 0; b < UsernameRules.BLOCKED_WORDS.length; b++) {
        if (list[w].indexOf(UsernameRules.BLOCKED_WORDS[b]) === 0) {
          return "blocked_word";
        }
      }
      for (let b = 0; b < STRONG_WORDS.length; b++) {
        if (list[w].indexOf(STRONG_WORDS[b]) >= 0) {
          return "blocked_word";
        }
      }
    }
    return "";
  }

  // The text the checks read: lower case, every decimal digit (and look-alike) as an ASCII digit,
  // fullwidth ASCII as ASCII, accented and look-alike letters plain, other spaces and dashes as " "
  // and "-", combining accents dropped.
  export function normalize(text: string): string {
    const folds = getFolds();
    const input = Util.chars(text);
    let out = "";
    for (let i = 0; i < input.length; i++) {
      const ch = input[i];
      const c = Util.codePoints(ch)[0];
      if (c < 0x80) {
        out += ch.toLowerCase();
      } else if (c >= 0x300 && c <= 0x36F) {
        continue;
      } else if (Util.has(folds, ch)) {
        out += folds[ch];
      } else {
        const low = ch.toLowerCase();
        out += Util.has(folds, low) ? folds[low] : low;
      }
    }
    return out;
  }

  function getFolds(): { [ch: string]: string } {
    if (foldMap !== null) {
      return foldMap;
    }
    const map: { [ch: string]: string } = {};
    for (let z = 0; z < DIGIT_ZEROS.length; z++) {
      for (let d = 0; d < 10; d++) {
        map[Util.fromCodePoint(DIGIT_ZEROS[z] + d)] = String(d);
      }
    }
    for (let l = 0; l < DIGIT_LOOKALIKES.length; l++) {
      const digits = Util.chars(DIGIT_LOOKALIKES[l]);
      for (let d = 0; d < digits.length; d++) {
        map[digits[d]] = String(d);
      }
    }
    for (let c = 0xFF01; c < 0xFF5F; c++) {
      map[String.fromCharCode(c)] = String.fromCharCode(c - 0xFEE0).toLowerCase();
    }
    for (let f = 0; f < CHAR_FOLDS.length; f++) {
      const chs = Util.chars(CHAR_FOLDS[f][1]);
      for (let i = 0; i < chs.length; i++) {
        map[chs[i]] = CHAR_FOLDS[f][0];
      }
    }
    foldMap = map;
    return map;
  }

  // The words of a message for the bad-word check, "l33t" digits read as letters; a run of single
  // letters is joined into one word ("s t u p i d").
  function words(text: string): string[] {
    let s = text.toLowerCase();
    for (let i = 0; i < UsernameRules.LEET.length; i++) {
      const k = UsernameRules.LEET[i][0];
      if (k >= "0" && k <= "9") {
        s = Util.replaceAll(s, k, UsernameRules.LEET[i][1]);
      }
    }
    const out: string[] = [];
    let letters = "";
    const parts = s.replace(NON_LETTER_RE, " ").split(" ");
    for (let i = 0; i < parts.length; i++) {
      const w = parts[i];
      if (w === "") {
        continue;
      }
      if (w.length === 1) {
        letters += w;
        continue;
      }
      if (letters.length > 1) {
        out.push(letters);
      }
      letters = "";
      out.push(w);
    }
    if (letters.length > 1) {
      out.push(letters);
    }
    return out;
  }

  // --- Channel messages (server only) ---

  export interface Content {
    text?: string;
    emote?: string;
  }

  // A channel message's content: exactly {"text": "<string>"} or {"emote": "<id>"}; else null.
  export function parseContent(raw: unknown): Content | null {
    let data: unknown;
    try {
      data = typeof raw === "string" ? JSON.parse(raw) : raw;
    } catch (_e) {
      return null;
    }
    if (!Util.isObject(data)) {
      return null;
    }
    const keys = Object.keys(data);
    if (keys.length !== 1) {
      return null;
    }
    if (keys[0] === "text" && typeof data.text === "string") {
      return { text: data.text };
    }
    if (keys[0] === "emote" && typeof data.emote === "string" && EMOTE_RE.test(data.emote)) {
      return { emote: data.emote };
    }
    return null;
  }

  // A message at a channel's chat level (AccountRules.chatLevel): {content} to send or {error}.
  export function checkContent(content: Content, level: string): { content?: Content; error?: string } {
    if (level !== AccountRules.CHAT_QUICK && level !== AccountRules.CHAT_FILTERED) {
      return { error: "chat_off" };
    }
    if (content.emote !== undefined) {
      return { content: { emote: content.emote } };
    }
    const r = check(content.text || "", level === AccountRules.CHAT_FILTERED ? AccountRules.TEEN_PLUS : AccountRules.UNDER_13);
    return r.error ? { error: r.error } : { content: { text: r.text } };
  }

  // --- History (M4 Wave 2, agent E; spec §17.2): 13+ only, the last 30 days ---

  export const DM_TYPE = 2; // Nakama's direct-message channel type
  export const HISTORY_DAYS = 30;
  export const PURGE_BATCH = 100; // old messages looked at each time a kept DM opens

  // Whether a channel keeps its messages: only a DM between two players at the text level (13+ with
  // text chat). Never a team room, and never with an under_13 player (quick chat keeps nothing).
  export function keepsHistory(type: number, levels: string[]): boolean {
    if (type !== DM_TYPE || levels.length !== 2) {
      return false;
    }
    for (let i = 0; i < levels.length; i++) {
      if (levels[i] !== AccountRules.CHAT_FILTERED) {
        return false;
      }
    }
    return true;
  }

  // A kept message's time as unix seconds: Nakama's number (seconds; milliseconds read as seconds)
  // or a time text; 0 when unreadable.
  export function createSeconds(value: unknown): number {
    if (typeof value === "number" && isFinite(value)) {
      return value > 1e11 ? Math.floor(value / 1000) : value;
    }
    if (typeof value === "string") {
      const ms = Date.parse(value);
      return isNaN(ms) ? 0 : Math.floor(ms / 1000);
    }
    return 0;
  }

  // Older than HISTORY_DAYS (an unreadable time, 0, is kept: never guessed away).
  export function isExpired(createTimeSec: number, nowMs: number): boolean {
    return createTimeSec > 0 && createTimeSec * 1000 < nowMs - HISTORY_DAYS * 86400 * 1000;
  }

  // The level of a channel: the strictest of its players' (off < quick < filtered).
  export function strictest(levels: string[]): string {
    if (levels.length === 0) {
      return AccountRules.CHAT_OFF;
    }
    let best = AccountRules.CHAT_FILTERED;
    for (let i = 0; i < levels.length; i++) {
      if (levels[i] === AccountRules.CHAT_OFF || !AccountRules.isChat(levels[i])) {
        return AccountRules.CHAT_OFF;
      }
      if (levels[i] === AccountRules.CHAT_QUICK) {
        best = AccountRules.CHAT_QUICK;
      }
    }
    return best;
  }
}
