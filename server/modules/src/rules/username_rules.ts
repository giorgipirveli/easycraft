// Username checks (spec §5.13), ported from the game's core/validation/username_rules.gd with the
// same word lists and test cases, so the server refuses what the game refuses. Keep both in step:
// server/modules/test/username_rules.test.ts mirrors tests/unit/test_username_rules.gd.

namespace UsernameRules {
  export const MIN_LEN = 3;
  export const MAX_LEN = 16;
  export const MAX_DIGITS = 6; // 7+ digits anywhere (even split by _) could be a phone number

  // Stems of 4+ letters, matched anywhere in the name except inside INNOCENT_WORDS.
  export const BLOCKED_WORDS: string[] = [
    "stupid", "idiot", "dumb", "loser", "moron", "hate", "kill", "murder", "suicide",
    "nazi", "hitler", "racist", "porn", "sexy", "nude", "naked", "fuck", "shit", "bitch",
    "dick", "cock", "pussy", "slut", "whore", "bastard", "damn", "crap", "penis", "vagina",
    "boob", "drug", "weed", "cocaine",
  ];
  // Innocent words with a blocked stem inside (the Scunthorpe problem).
  export const INNOCENT_WORDS: string[] = [
    "peacock", "hancock", "hitchcock", "shuttlecock", "woodcock", "cockatoo", "cockatiel", "cockpit",
    "cockroach", "cocker", "whatever", "chateau", "skill", "scrap", "dickens", "dickinson", "dickory",
    "tweed", "weedle", "closer", "dumbo", "dumbledore", "dumbbell",
  ];
  // In the game's order (a GDScript dictionary keeps it).
  export const LEET: string[][] = [
    ["0", "o"], ["1", "i"], ["3", "e"], ["4", "a"], ["5", "s"], ["7", "t"], ["8", "b"], ["_", ""],
  ];

  const CHARS_RE = /^[A-Za-z0-9_]+$/;

  export function normalize(name: string): string {
    return Util.stripEdges(name);
  }

  // The key two names share when they differ only in case: "Hopper_7" and "hopper_7" are one name.
  export function uniquenessKey(name: string): string {
    return normalize(name).toLowerCase();
  }

  // "" when valid, else one of: too_short, too_long, bad_chars, must_start_with_letter,
  // personal_info, blocked_word.
  export function validate(name: unknown): string {
    const n = typeof name === "string" ? normalize(name) : "";
    const length = Util.codePointLength(n);
    if (length < MIN_LEN) {
      return "too_short";
    }
    if (length > MAX_LEN) {
      return "too_long";
    }
    if (!CHARS_RE.test(n)) {
      return "bad_chars";
    }
    const first = n.charCodeAt(0);
    if (!((first >= 65 && first <= 90) || (first >= 97 && first <= 122))) {
      return "must_start_with_letter";
    }
    let digits = 0;
    for (let i = 0; i < n.length; i++) {
      const c = n.charCodeAt(i);
      if (c >= 48 && c <= 57) {
        digits++;
      }
    }
    if (digits > MAX_DIGITS) {
      return "personal_info";
    }
    const plain = n.toLowerCase();
    let unleet = plain;
    for (let i = 0; i < LEET.length; i++) {
      unleet = Util.replaceAll(unleet, LEET[i][0], LEET[i][1]);
    }
    const texts = [coverInnocent(plain), coverInnocent(unleet)];
    for (let t = 0; t < texts.length; t++) {
      for (let w = 0; w < BLOCKED_WORDS.length; w++) {
        if (texts[t].indexOf(BLOCKED_WORDS[w]) >= 0) {
          return "blocked_word";
        }
      }
    }
    return "";
  }

  // Covers each innocent word with "|", so the stem inside it no longer matches and no new word can
  // form across the cover ("peacock_dick" -> "|_dick").
  function coverInnocent(text: string): string {
    for (let i = 0; i < INNOCENT_WORDS.length; i++) {
      text = Util.replaceAll(text, INNOCENT_WORDS[i], "|");
    }
    return text;
  }
}
