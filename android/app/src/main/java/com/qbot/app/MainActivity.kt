package com.qbot.app

import android.app.Activity
import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient

/**
 * QBot 主界面。
 *
 * 目前用 WebView 承载前端页面（便于快速迭代样式），
 * 后续会通过 @JavascriptInterface 暴露原生能力：
 *   - 下载 rootfs / QQ 安装包
 *   - 解压、安装、启动 proot 容器
 *   - 读取日志、二维码
 */
class MainActivity : Activity() {

    private lateinit var web: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        web = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowFileAccess = true
            settings.useWideViewPort = true
            settings.loadWithOverviewMode = true
            webViewClient = WebViewClient()
            setBackgroundColor(0xFF0E1116.toInt())
            loadUrl("file:///android_asset/www/index.html")
        }

        setContentView(web)
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        if (this::web.isInitialized && web.canGoBack()) {
            web.goBack()
        } else {
            super.onBackPressed()
        }
    }

    override fun onDestroy() {
        if (this::web.isInitialized) {
            web.destroy()
        }
        super.onDestroy()
    }
}
