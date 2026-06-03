package com.pawcket.pawcket

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class PawcketWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pawcket_widget).apply {
                // Get dynamic expression of Mr. Oyen, defaults to lazyass_oyen
                val imageName = widgetData.getString("mr_oyen_image", "lazyass_oyen")
                val imgResId = context.resources.getIdentifier(imageName, "drawable", context.packageName)
                if (imgResId != 0) {
                    setImageViewResource(R.id.widget_oyen_image, imgResId)
                } else {
                    setImageViewResource(R.id.widget_oyen_image, R.drawable.lazyass_oyen)
                }

                // Get dynamic status text
                val statusText = widgetData.getString("status_text", "Pawcket - Logging Expense")
                setTextViewText(R.id.widget_status_text, statusText)

                // Get dynamic input/display text
                val inputText = widgetData.getString("display_text", "Tap to log: 'Makan sate 25k'")
                setTextViewText(R.id.widget_input_text, inputText)

                // Setup click intents for home_widget package
                val typeIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("pawcket://type_expense"))
                setOnClickPendingIntent(R.id.btn_widget_input, typeIntent)

                val micIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("pawcket://voice_input"))
                setOnClickPendingIntent(R.id.btn_widget_mic, micIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
