class_name TheaterEmbed
extends RefCounted
## The page the Android player (EasyCraftWebView) shows: YouTube's official embedded player (IFrame Player API,
## privacy-enhanced youtube-nocookie.com host), filling the whole view with nothing drawn over it (spec §5.12). The
## page's script only tells the game two things: the video ended (`EasyCraft.ended()`) or it could not play
## (`EasyCraft.failed(code)`); `window.ecPause()` lets the game pause it before hiding the view. The browser's
## player is the web page's own block (web/shell.html, WebGlue); both use the same settings.
##
## The page is loaded with base URL `base_url(referer)` (TheaterRules.referer(): https://<the app's package>),
## which the player sees as the Referer identifying the app. The id is checked (TheaterChannels.is_video_id) and
## the Referer must be a package name before either goes into the page, so no list text can become code. Owner #89:
## YouTube only (every Theater video is made for kids; TikTok has no such setting).

const YOUTUBE_HOSTS: Array[String] = ["youtube-nocookie.com", "youtube.com", "google.com"]

const _HEAD := """<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;background:#000}
#player{position:absolute;left:0;top:0;width:100%;height:100%;border:0}</style></head>
"""

const _SEND := """function send(kind,arg){try{if(!window.EasyCraft)return;if(kind==='ended'){EasyCraft.ended();}else{EasyCraft.failed(String(arg));}}catch(e){}}
"""

const _YOUTUBE := """<body><div id="player"></div>
<script>var player=null;
%s
function onYouTubeIframeAPIReady(){player=new YT.Player('player',{width:'100%%',height:'100%%',host:'https://www.youtube-nocookie.com',videoId:'%s',
playerVars:{autoplay:%d,playsinline:1,rel:0,fs:0,iv_load_policy:3,disablekb:1,origin:'%s'},
events:{onStateChange:function(e){if(e.data===0){send('ended');}},onError:function(e){send('failed',e.data);}}});}
window.ecPause=function(){try{if(player&&player.pauseVideo){player.pauseVideo();}}catch(e){}};
</script><script src="https://www.youtube.com/iframe_api"></script></body></html>
"""

static var _referer := RegEx.create_from_string("^https://[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")


static func base_url(referer: String) -> String:
	return referer + "/"


## The whole page for one video, or "" when it must not (or can't) be shown. `autoplay`: the child picked it.
static func page(platform: StringName, video_id: String, autoplay: bool, referer: String) -> String:
	if platform != TheaterChannels.YOUTUBE or not TheaterChannels.is_video_id(platform, video_id):
		return ""
	if _referer.search(referer) == null:
		return ""
	return _HEAD + _YOUTUBE % [_SEND, video_id, 1 if autoplay else 0, referer]


## The hosts the player's frames may load from; the plugin refuses every other navigation.
static func hosts() -> PackedStringArray:
	return PackedStringArray(YOUTUBE_HOSTS)
