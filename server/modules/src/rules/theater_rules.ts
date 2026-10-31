// The Theater's channel list (spec §5.12, §14.12; owner #89, module 0.2.17): what the server checks before it
// keeps a list the owner sends (theater_set_channels, tools/theater_list.py). The shape is the one the game
// reads (core/theater/theater_channels.gd, data/theater/channels.json):
//
//   {"enabled": bool, "channels": [{"id", "title", "platform", "color"?, "icon"?,
//     "videos": [{"id", "title", "made_for_kids", "from"?}]}]}
//
// "enabled" is the kill-switch (false: no Theater in any game that reads this list). The server refuses a list
// with any mistake and names each one, so a typo never reaches the children (the game still reads the list
// defensively: it drops what it can't use). Every video id is checked per platform, so no text from the list can
// become code in the player's page. The kept list has only these fields, "source": "server" and "updated_ms".

namespace TheaterListRules {
  export const VERSION = 1;
  export const MAX_CHANNELS = 12;
  export const MAX_VIDEOS = 50;
  export const MAX_TITLE = 40; // characters (the game's TheaterChannels.MAX_TITLE)
  export const MAX_FROM = 30; // the video's maker, shown small on its card
  export const MAX_CHARS = 64 * 1024; // the RPC's payload (every other RPC takes 4 KiB, Util.MAX_PAYLOAD)
  export const PLATFORMS = ["youtube", "tiktok"];
  // The pictures the game draws on a channel's tab (TheaterIcons); none or an unknown one: "tv".
  export const ICONS = ["tv", "planet", "flask", "paw", "gear", "note", "palette", "pyramid", "star"];
  export const SOURCE = "server";

  const CHANNEL_ID = /^[a-z0-9_]{1,32}$/;
  const YOUTUBE_ID = /^[A-Za-z0-9_-]{11}$/;
  const TIKTOK_ID = /^[0-9]{6,25}$/;
  const COLOR = /^#[0-9a-fA-F]{6}$/;

  export interface Checked {
    list?: Util.Json; // the list to keep, when there is no problem
    problems: string[]; // what is wrong, each with where ("channels[2].videos[5].id: ...")
  }

  export function isVideoId(platform: string, id: unknown): boolean {
    if (typeof id !== "string") {
      return false;
    }
    if (platform === "youtube") {
      return YOUTUBE_ID.test(id);
    }
    if (platform === "tiktok") {
      return TIKTOK_ID.test(id);
    }
    return false;
  }

  // A title (or a maker's name): trimmed, 1..max characters, no control characters. null when it is not one.
  export function text(value: unknown, max: number): string | null {
    if (typeof value !== "string") {
      return null;
    }
    const t = Util.stripEdges(value);
    const cps = Util.codePoints(t);
    if (cps.length === 0 || cps.length > max) {
      return null;
    }
    for (let i = 0; i < cps.length; i++) {
      if (cps[i] < 32 || cps[i] === 127) {
        return null;
      }
    }
    return t;
  }

  export function check(value: unknown, nowMs: number): Checked {
    const problems: string[] = [];
    if (!Util.isObject(value)) {
      return { problems: ["the list is not a JSON object"] };
    }
    if (JSON.stringify(value).length > MAX_CHARS) {
      return { problems: ["the list is bigger than " + MAX_CHARS + " characters"] };
    }
    if (typeof value.enabled !== "boolean") {
      problems.push("enabled: must be true or false (false switches the Theater off)");
    }
    const channels: Util.Json[] = [];
    if (!Array.isArray(value.channels)) {
      problems.push("channels: must be a list");
    } else if (value.channels.length > MAX_CHANNELS) {
      problems.push("channels: at most " + MAX_CHANNELS);
    } else {
      const seen: Util.Json = {};
      for (let i = 0; i < value.channels.length; i++) {
        const c = channel(value.channels[i], "channels[" + i + "]", problems);
        if (c === null) {
          continue;
        }
        if (Util.has(seen, c.id)) {
          problems.push("channels[" + i + "].id: \"" + c.id + "\" is there twice");
          continue;
        }
        seen[c.id] = true;
        channels.push(c);
      }
    }
    if (problems.length > 0) {
      return { problems: problems };
    }
    return {
      list: { version: VERSION, enabled: value.enabled, source: SOURCE, updated_ms: nowMs, channels: channels },
      problems: [],
    };
  }

  function channel(value: unknown, at: string, problems: string[]): Util.Json | null {
    if (!Util.isObject(value)) {
      problems.push(at + ": must be an object");
      return null;
    }
    const before = problems.length;
    const id = value.id;
    if (typeof id !== "string" || !CHANNEL_ID.test(id)) {
      problems.push(at + ".id: 1-32 of a-z, 0-9 and _");
    }
    const title = text(value.title, MAX_TITLE);
    if (title === null) {
      problems.push(at + ".title: 1-" + MAX_TITLE + " characters");
    }
    const platform = value.platform;
    if (typeof platform !== "string" || PLATFORMS.indexOf(platform) < 0) {
      problems.push(at + ".platform: " + PLATFORMS.join(" or "));
    }
    if (value.color !== undefined && (typeof value.color !== "string" || !COLOR.test(value.color))) {
      problems.push(at + ".color: like \"#3a7be8\"");
    }
    if (value.icon !== undefined && (typeof value.icon !== "string" || ICONS.indexOf(value.icon) < 0)) {
      problems.push(at + ".icon: one of " + ICONS.join(", "));
    }
    const videos: Util.Json[] = [];
    if (!Array.isArray(value.videos) || value.videos.length === 0) {
      problems.push(at + ".videos: a list of at least one video");
    } else if (value.videos.length > MAX_VIDEOS) {
      problems.push(at + ".videos: at most " + MAX_VIDEOS);
    } else {
      const seen: Util.Json = {};
      for (let i = 0; i < value.videos.length; i++) {
        const v = video(value.videos[i], String(platform), at + ".videos[" + i + "]", problems);
        if (v === null) {
          continue;
        }
        if (Util.has(seen, v.id)) {
          problems.push(at + ".videos[" + i + "].id: \"" + v.id + "\" is there twice");
          continue;
        }
        seen[v.id] = true;
        videos.push(v);
      }
    }
    if (problems.length > before) {
      return null;
    }
    const out: Util.Json = { id: id, title: title, platform: platform };
    if (value.color !== undefined) {
      out.color = value.color;
    }
    if (value.icon !== undefined) {
      out.icon = value.icon;
    }
    out.videos = videos;
    return out;
  }

  function video(value: unknown, platform: string, at: string, problems: string[]): Util.Json | null {
    if (!Util.isObject(value)) {
      problems.push(at + ": must be an object");
      return null;
    }
    const before = problems.length;
    if (!isVideoId(platform, value.id)) {
      problems.push(at + ".id: not a " + platform + " video id");
    }
    const title = text(value.title, MAX_TITLE);
    if (title === null) {
      problems.push(at + ".title: 1-" + MAX_TITLE + " characters");
    }
    if (typeof value.made_for_kids !== "boolean") {
      problems.push(at + ".made_for_kids: true or false (the game shows only true)");
    }
    let from: string | null = null;
    if (value.from !== undefined) {
      from = text(value.from, MAX_FROM);
      if (from === null) {
        problems.push(at + ".from: 1-" + MAX_FROM + " characters");
      }
    }
    if (problems.length > before) {
      return null;
    }
    const out: Util.Json = { id: value.id, title: title, made_for_kids: value.made_for_kids };
    if (from !== null) {
      out.from = from;
    }
    return out;
  }

  // How big a kept list is, for the owner's answer.
  export function count(list: Util.Json): { channels: number; videos: number } {
    let videos = 0;
    const channels = Array.isArray(list.channels) ? list.channels : [];
    for (let i = 0; i < channels.length; i++) {
      videos += Array.isArray(channels[i].videos) ? channels[i].videos.length : 0;
    }
    return { channels: channels.length, videos: videos };
  }
}
