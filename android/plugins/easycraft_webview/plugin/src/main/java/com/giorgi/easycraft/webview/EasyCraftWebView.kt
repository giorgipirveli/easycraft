package com.giorgi.easycraft.webview

import android.annotation.SuppressLint
import android.app.Activity
import android.graphics.Color
import android.os.Message
import android.util.Log
import android.view.Gravity
import android.view.View
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/**
 * The Shorts Theater's player (EasyCraft spec §5.12, M3 Task 17).
 *
 * One WebView, placed at the rectangle Godot asks for (screen pixels) above the game view. Godot
 * draws the Theater's buttons beside that rectangle, never on it. The page is the HTML that Godot
 * builds (`TheaterEmbed` in the game): the official YouTube or TikTok embedded player filling the
 * view, loaded with the app's base URL, which is also the Referer the player sees.
 *
 * Children's-game rules: the page can never navigate away (every main-frame navigation is refused,
 * so there are no links out and no endless feed), sub-frames only load from the hosts Godot allows,
 * no popups, no file or content access, no geolocation; for a child's profile no third-party
 * cookies and no autoplay (the child taps play). The view never takes key focus, so Android's Back
 * button still reaches the game.
 *
 * Signals: `video_ended` (the player reported the end of the video) and `video_failed(code)`.
 */
class EasyCraftWebView(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val TAG = "EasyCraftWebView"
    }

    private var layout: FrameLayout? = null
    private var webView: WebView? = null

    @Volatile
    private var allowedHosts: List<String> = emptyList()

    override fun getPluginName() = BuildConfig.GODOT_PLUGIN_NAME

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo("video_ended"),
        SignalInfo("video_failed", String::class.java),
    )

    /** A full-size, see-through layer above the game view; it never takes touches itself. */
    override fun onMainCreate(activity: Activity?): View? {
        if (activity == null) {
            return null
        }
        val l = FrameLayout(activity)
        l.isClickable = false
        l.isFocusable = false
        layout = l
        return l
    }

    /**
     * Shows [html] (loaded as if it came from [baseUrl]) at x, y, w, h in screen pixels.
     * [hosts] is a comma-separated list of hosts the player's frames may load from.
     */
    @UsedByGodot
    fun show_page(html: String, baseUrl: String, hosts: String, child: Boolean, autoplay: Boolean,
                  x: Int, y: Int, w: Int, h: Int) {
        allowedHosts = hosts.split(",").map { it.trim().lowercase() }.filter { it.isNotEmpty() }
        runOnHostThread {
            val view = webView ?: create() ?: return@runOnHostThread
            view.settings.mediaPlaybackRequiresUserGesture = child || !autoplay
            CookieManager.getInstance().setAcceptThirdPartyCookies(view, !child)
            place(view, x, y, w, h)
            view.visibility = View.VISIBLE
            view.onResume()
            view.loadDataWithBaseURL(baseUrl, html, "text/html", "utf-8", null)
        }
    }

    /** Moves the player (the screen was resized or rotated). */
    @UsedByGodot
    fun set_rect(x: Int, y: Int, w: Int, h: Int) {
        runOnHostThread {
            webView?.let { place(it, x, y, w, h) }
        }
    }

    /** Pauses the video and hides the player (the pause menu or the block palette is open). */
    @UsedByGodot
    fun hide() {
        runOnHostThread {
            webView?.let {
                it.evaluateJavascript("window.ecPause && window.ecPause();", null)
                it.visibility = View.GONE
            }
        }
    }

    /** Shows the hidden player again; the video stays paused until the player taps it. */
    @UsedByGodot
    fun reveal() {
        runOnHostThread {
            webView?.visibility = View.VISIBLE
        }
    }

    /** Stops everything and frees the WebView (the player left the Theater). */
    @UsedByGodot
    fun close() {
        runOnHostThread { destroy() }
    }

    override fun onMainPause() {
        webView?.let {
            it.evaluateJavascript("window.ecPause && window.ecPause();", null)
            it.onPause()
        }
    }

    override fun onMainResume() {
        webView?.onResume()
    }

    override fun onMainDestroy() {
        destroy()
    }

    @SuppressLint("SetJavaScriptEnabled", "JavascriptInterface")
    private fun create(): WebView? {
        val parent = layout ?: return null
        val view = WebView(parent.context)
        view.setBackgroundColor(Color.BLACK)
        view.isFocusable = false
        view.isFocusableInTouchMode = false
        with(view.settings) {
            javaScriptEnabled = true           // the official players need it
            domStorageEnabled = true
            allowFileAccess = false
            allowContentAccess = false
            setGeolocationEnabled(false)
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
            javaScriptCanOpenWindowsAutomatically = false
            setSupportMultipleWindows(true)    // so that onCreateWindow can refuse every popup
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            mediaPlaybackRequiresUserGesture = true
        }
        view.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(v: WebView, request: WebResourceRequest): Boolean {
                val allowed = !request.isForMainFrame && isAllowed(request.url.scheme, request.url.host)
                if (!allowed) {
                    Log.i(TAG, "Refused navigation to ${request.url}")
                }
                return !allowed
            }
        }
        view.webChromeClient = object : WebChromeClient() {
            override fun onCreateWindow(v: WebView, isDialog: Boolean, isUserGesture: Boolean, resultMsg: Message): Boolean {
                Log.i(TAG, "Refused a popup window")
                return false
            }
        }
        view.addJavascriptInterface(Bridge(), "EasyCraft")
        parent.addView(view, FrameLayout.LayoutParams(1, 1))
        webView = view
        return view
    }

    private fun isAllowed(scheme: String?, host: String?): Boolean {
        if (scheme != "https" || host == null) {
            return false
        }
        val h = host.lowercase()
        return allowedHosts.any { h == it || h.endsWith(".$it") }
    }

    private fun place(view: WebView, x: Int, y: Int, w: Int, h: Int) {
        val params = FrameLayout.LayoutParams(maxOf(w, 1), maxOf(h, 1))
        params.gravity = Gravity.TOP or Gravity.START
        params.leftMargin = x
        params.topMargin = y
        view.layoutParams = params
    }

    private fun destroy() {
        val view = webView ?: return
        webView = null
        view.stopLoading()
        view.loadUrl("about:blank")
        layout?.removeView(view)
        view.destroy()
    }

    /** What the page's script may tell the game: only these two harmless events. */
    private inner class Bridge {
        @JavascriptInterface
        fun ended() {
            emitSignal("video_ended")
        }

        @JavascriptInterface
        fun failed(code: String) {
            emitSignal("video_failed", code.take(40))
        }
    }
}
