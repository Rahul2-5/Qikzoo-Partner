package com.qikzoodelivery
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
class MainActivity : FlutterActivity() {
  private val prefs by lazy { getSharedPreferences("referral", MODE_PRIVATE) }
  override fun onCreate(state: Bundle?) { super.onCreate(state); capture(intent); installReferrer() }
  override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); setIntent(intent); capture(intent) }
  override fun configureFlutterEngine(engine: io.flutter.embedding.engine.FlutterEngine) { super.configureFlutterEngine(engine); MethodChannel(engine.dartExecutor.binaryMessenger, "com.qikzoodelivery/referral").setMethodCallHandler { call, result -> if (call.method == "getReferralCode") result.success(prefs.getString("code", null)) else result.notImplemented() } }
  private fun capture(intent: Intent?) = save(intent?.data?.getQueryParameter("ref"))
  private fun installReferrer() { val client = InstallReferrerClient.newBuilder(this).build(); client.startConnection(object : InstallReferrerStateListener { override fun onInstallReferrerSetupFinished(code: Int) { if(code == InstallReferrerClient.InstallReferrerResponse.OK) { save(Uri.parse("https://qikzoo.com/?" + client.installReferrer.installReferrer).getQueryParameter("ref")); client.endConnection() } }; override fun onInstallReferrerServiceDisconnected() {} }) }
  private fun save(raw: String?) { val code = raw?.trim()?.uppercase(); if(code != null && Regex("^[A-Z0-9]{6,24}$").matches(code)) prefs.edit().putString("code", code).apply() }
}
