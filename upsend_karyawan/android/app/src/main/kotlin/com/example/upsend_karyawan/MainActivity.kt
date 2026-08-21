package com.example.upsend_karyawan

import android.Manifest
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "com.example.upsend_karyawan/radius"
	private val geofenceId = "active_attendance_radius"
	private lateinit var geofencingClient: GeofencingClient

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		geofencingClient = LocationServices.getGeofencingClient(this)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"registerGeofence" -> {
						val latitude = call.argument<Double>("latitude")
						val longitude = call.argument<Double>("longitude")
						val radius = call.argument<Double>("radius")
						if (latitude == null || longitude == null || radius == null) {
							result.error("INVALID_LOCATION", "Koordinat lokasi tidak valid.", null)
						} else {
							registerGeofence(latitude, longitude, radius, result)
						}
					}
					"unregisterGeofence" -> {
						geofencingClient.removeGeofences(geofencePendingIntent)
							.addOnCompleteListener { result.success(null) }
					}
					else -> result.notImplemented()
				}
			}
	}

	private val geofencePendingIntent: PendingIntent by lazy {
		val intent = Intent(this, RadiusGeofenceReceiver::class.java)
		PendingIntent.getBroadcast(
			this,
			1001,
			intent,
			PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
		)
	}

	private fun registerGeofence(
		latitude: Double,
		longitude: Double,
		radius: Double,
		result: MethodChannel.Result
	) {
		if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
			!= PackageManager.PERMISSION_GRANTED
		) {
			result.error("LOCATION_PERMISSION", "Izin lokasi belum diberikan.", null)
			return
		}

		val geofence = Geofence.Builder()
			.setRequestId(geofenceId)
			.setCircularRegion(latitude, longitude, radius.toFloat())
			.setExpirationDuration(Geofence.NEVER_EXPIRE)
			.setTransitionTypes(Geofence.GEOFENCE_TRANSITION_EXIT)
			.build()

		val request = GeofencingRequest.Builder()
			.setInitialTrigger(0)
			.addGeofence(geofence)
			.build()

		geofencingClient.removeGeofences(geofencePendingIntent).addOnCompleteListener {
			geofencingClient.addGeofences(request, geofencePendingIntent)
				.addOnSuccessListener { result.success(null) }
				.addOnFailureListener { error ->
					result.error("GEOFENCE_FAILED", error.message, null)
				}
		}
	}
}
