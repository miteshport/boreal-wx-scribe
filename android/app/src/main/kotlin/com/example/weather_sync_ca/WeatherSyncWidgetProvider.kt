package com.example.weather_sync_ca

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONObject
import org.json.JSONArray

class WeatherSyncWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            updateAppWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val widgetData = HomeWidgetPlugin.getData(context)
        updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // 1. JSON parsing with safety fallbacks
            val payloadString = widgetData.getString("widget_master_payload", "{}") ?: "{}"
            var temp = "--"
            var condition = "SYNCING..."
            var location = "OUTLOOK: SYNCING..."
            var highLow = "TREND: STABLE"
            var badge = "AQHI: AWAITING PULSE"
            var slangHeadline = "🍁 WEATHER SYNC: STABLE"
            var lifestyleActivity = "TACTICAL OUTLOOK: STABLE"
            var newcomerWisdom = "TACTICAL OUTLOOK: STABLE"
            var hourlyArr = JSONArray()
            var weeklyArr = JSONArray()

            try {
                val json = JSONObject(payloadString)
                temp = json.optString("temp", "--")
                condition = json.optString("condition", "SYNCING...")
                location = json.optString("location", "OUTLOOK: SYNCING...")
                highLow = json.optString("high_low", "TREND: STABLE")
                badge = json.optString("aqhi_badge", "AQHI: AWAITING PULSE")
                slangHeadline = json.optString("widget_slang_headline", "🍁 WEATHER SYNC: STABLE")
                lifestyleActivity = json.optString("widget_lifestyle_activity", "TACTICAL OUTLOOK: STABLE")
                newcomerWisdom = json.optString("widget_newcomer_wisdom", "TACTICAL OUTLOOK: STABLE")
                hourlyArr = json.optJSONArray("hourly_6hr") ?: JSONArray()
                weeklyArr = json.optJSONArray("weekly_7day") ?: JSONArray()
            } catch (e: Exception) {
                // Fallbacks remain if parsing fails
            }

            // 2. Evaluate Tiers based on widget dimensions
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

            // 6-Tier Logic
            val isT6 = minWidth >= 250 && minHeight >= 250
            val isT5 = minWidth >= 250 && minHeight >= 180 && !isT6
            val isT4 = minWidth >= 250 && minHeight < 180
            val isT3 = minWidth >= 250 && minHeight < 110 // Wait, actually standard 4x1 is height ~40-100
            val isT2 = minWidth >= 110 && minWidth < 250 && minHeight >= 110
            val isT1 = minWidth < 110 || (minWidth < 250 && minHeight < 110)

            // Ensure exact classification
            val tier = when {
                isT6 -> 6
                isT5 -> 5
                isT4 -> 4
                isT3 -> 3
                isT2 -> 2
                else -> 1
            }

            // Tactical Crosshairs
            val crosshairVis = if (tier >= 4) View.VISIBLE else View.GONE
            setViewVisibility(R.id.crosshair_tl, crosshairVis)
            setViewVisibility(R.id.crosshair_tr, crosshairVis)
            setViewVisibility(R.id.crosshair_bl, crosshairVis)
            setViewVisibility(R.id.crosshair_br, crosshairVis)

            // Hide all tiers first
            setViewVisibility(R.id.tier1, View.GONE)
            setViewVisibility(R.id.tier2, View.GONE)
            setViewVisibility(R.id.tier3, View.GONE)
            setViewVisibility(R.id.tier4, View.GONE)
            setViewVisibility(R.id.tier5, View.GONE)
            setViewVisibility(R.id.tier6, View.GONE)

            // 3. Populate matching Tier
            when (tier) {
                1 -> {
                    setViewVisibility(R.id.tier1, View.VISIBLE)
                    setTextViewText(R.id.t1_temp, temp)
                    setTextViewText(R.id.t1_cond, condition)
                }
                2 -> {
                    setViewVisibility(R.id.tier2, View.VISIBLE)
                    setTextViewText(R.id.t2_temp, temp)
                    setTextViewText(R.id.t2_cond, condition)
                    setTextViewText(R.id.t2_loc, location)
                    setTextViewText(R.id.t2_trend, highLow)
                }
                3 -> {
                    setViewVisibility(R.id.tier3, View.VISIBLE)
                    setTextViewText(R.id.t3_temp, temp)
                    setTextViewText(R.id.t3_cond, condition)
                    setTextViewText(R.id.t3_loc, location)
                    
                    var hourlyText = ""
                    for (i in 0 until minOf(hourlyArr.length(), 4)) {
                        val h = hourlyArr.optJSONObject(i)
                        if (h != null) {
                            hourlyText += "${h.optString("time", "")} ${h.optString("temp", "")}   "
                        }
                    }
                    if (hourlyText.isEmpty()) hourlyText = highLow
                    setTextViewText(R.id.t3_hourly, hourlyText)
                }
                4 -> {
                    setViewVisibility(R.id.tier4, View.VISIBLE)
                    setTextViewText(R.id.t4_temp, temp)
                    setTextViewText(R.id.t4_cond, condition)
                    setTextViewText(R.id.t4_slang, slangHeadline)
                    setTextViewText(R.id.t4_loc, location)
                    
                    removeAllViews(R.id.t4_outlook_container)
                    for (i in 0 until minOf(weeklyArr.length(), 3)) {
                        val w = weeklyArr.optJSONObject(i)
                        if (w != null) {
                            val itemView = RemoteViews(context.packageName, R.layout.widget_weekly_item)
                            itemView.setTextViewText(R.id.weekly_day, w.optString("day", "-"))
                            itemView.setTextViewText(R.id.weekly_icon, w.optString("icon", "-"))
                            itemView.setTextViewText(R.id.weekly_high, w.optString("high", "-"))
                            itemView.setTextViewText(R.id.weekly_low, w.optString("low", "-"))
                            addView(R.id.t4_outlook_container, itemView)
                        }
                    }
                }
                5 -> {
                    setViewVisibility(R.id.tier5, View.VISIBLE)
                    setTextViewText(R.id.t5_temp, temp)
                    setTextViewText(R.id.t5_cond, condition)
                    setTextViewText(R.id.t5_lifestyle, lifestyleActivity)
                    setTextViewText(R.id.t5_loc, location)
                    
                    removeAllViews(R.id.t5_hourly_container)
                    for (i in 0 until minOf(hourlyArr.length(), 6)) {
                        val h = hourlyArr.optJSONObject(i)
                        if (h != null) {
                            val itemView = RemoteViews(context.packageName, R.layout.widget_hourly_item)
                            itemView.setTextViewText(R.id.hourly_time, h.optString("time", "-"))
                            itemView.setTextViewText(R.id.hourly_icon, h.optString("icon", "-"))
                            itemView.setTextViewText(R.id.hourly_temp, h.optString("temp", "-"))
                            addView(R.id.t5_hourly_container, itemView)
                        }
                    }
                    
                    removeAllViews(R.id.t5_weekly_container)
                    for (i in 0 until minOf(weeklyArr.length(), 3)) {
                        val w = weeklyArr.optJSONObject(i)
                        if (w != null) {
                            val itemView = RemoteViews(context.packageName, R.layout.widget_weekly_item)
                            itemView.setTextViewText(R.id.weekly_day, w.optString("day", "-"))
                            itemView.setTextViewText(R.id.weekly_icon, w.optString("icon", "-"))
                            itemView.setTextViewText(R.id.weekly_high, w.optString("high", "-"))
                            itemView.setTextViewText(R.id.weekly_low, w.optString("low", "-"))
                            addView(R.id.t5_weekly_container, itemView)
                        }
                    }
                }
                6 -> {
                    setViewVisibility(R.id.tier6, View.VISIBLE)
                    setTextViewText(R.id.t6_temp, temp)
                    setTextViewText(R.id.t6_cond, condition)
                    setTextViewText(R.id.t6_loc, location)
                    setTextViewText(R.id.t6_badge, badge)
                    setTextViewText(R.id.t6_wisdom, newcomerWisdom)
                    
                    removeAllViews(R.id.t6_hourly_container)
                    for (i in 0 until minOf(hourlyArr.length(), 6)) {
                        val h = hourlyArr.optJSONObject(i)
                        if (h != null) {
                            val itemView = RemoteViews(context.packageName, R.layout.widget_hourly_item)
                            itemView.setTextViewText(R.id.hourly_time, h.optString("time", "-"))
                            itemView.setTextViewText(R.id.hourly_icon, h.optString("icon", "-"))
                            itemView.setTextViewText(R.id.hourly_temp, h.optString("temp", "-"))
                            addView(R.id.t6_hourly_container, itemView)
                        }
                    }
                    
                    removeAllViews(R.id.t6_weekly_container)
                    for (i in 0 until minOf(weeklyArr.length(), 7)) {
                        val w = weeklyArr.optJSONObject(i)
                        if (w != null) {
                            val itemView = RemoteViews(context.packageName, R.layout.widget_weekly_item)
                            itemView.setTextViewText(R.id.weekly_day, w.optString("day", "-"))
                            itemView.setTextViewText(R.id.weekly_icon, w.optString("icon", "-"))
                            itemView.setTextViewText(R.id.weekly_high, w.optString("high", "-"))
                            itemView.setTextViewText(R.id.weekly_low, w.optString("low", "-"))
                            addView(R.id.t6_weekly_container, itemView)
                        }
                    }
                }
            }
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
