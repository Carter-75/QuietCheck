package com.example.quietcheck

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.WorkManager
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import java.util.concurrent.TimeUnit

/// Boot completion receiver to restart background tasks
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Restart background data collection tasks
            scheduleBackgroundTasks(context)
        }
    }

    private fun scheduleBackgroundTasks(context: Context) {
        val workManager = WorkManager.getInstance(context)
        
        // Schedule periodic data collection (every 6 hours)
        val dataCollectionRequest = PeriodicWorkRequestBuilder<DataCollectionWorker>(
            6, TimeUnit.HOURS,
            15, TimeUnit.MINUTES // Flex interval
        ).build()
        
        workManager.enqueueUniquePeriodicWork(
            "data_collection",
            ExistingPeriodicWorkPolicy.KEEP,
            dataCollectionRequest
        )
    }
}