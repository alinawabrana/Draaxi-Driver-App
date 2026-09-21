# Driver Home Screen Backend Integration Spec

## Home Flow
1. Driver opens Home.
2. App fetches profile/approval state.
3. Driver toggles Online.
4. Backend sends incoming ride requests (can be multiple concurrently).
5. Driver can Accept, Decline, or Offer Fare.
6. On Accept:
   - Phase A: navigate to rider pickup.
   - When near pickup, app shows "reached rider" + Start Ride.
   - Phase B: navigate to destination.
7. Ride completes/cancels, driver returns to request-listening state.

## Backend Data Needed

### For driver status
- `driver_id`
- `is_online`
- `is_approved`
- `documents_complete`

### For driver location updates
- `driver_id`
- `lat`, `lng`
- optional: `heading`, `speed`, `accuracy`, `timestamp`

### For ride request card
- `request_id`
- `rider_id`, `rider_name`, optional `rider_phone`, `rider_avatar`
- `pickup_address`, `pickup_lat`, `pickup_lng`
- `dropoff_address`, `dropoff_lat`, `dropoff_lng`
- `distance_km`, `eta_min`
- `suggested_fare`
- `expires_at` or `ttl_seconds`
- `created_at`
- `status` (`pending`, `accepted`, `expired`, `cancelled`, etc.)

### For accepted ride session
- `ride_id`
- `request_id`
- `phase` (`to_rider`, `to_destination`)
- `rider_reached` (bool)
- `remaining_distance_km`
- `remaining_eta_min`
- `route_polyline` (recommended)
- `status` (`active`, `completed`, `cancelled`)

## Required Driver Actions APIs
- `POST /driver/status` (online/offline)
- `POST /driver/location`
- `POST /driver/requests/{id}/accept`
- `POST /driver/requests/{id}/decline`
- `POST /driver/requests/{id}/offer-fare`
- `POST /driver/rides/{id}/start` (start after reaching rider)
- `POST /driver/rides/{id}/complete` / cancel endpoints

## Should Backend Be Streamed Periodically?
Yes, for this screen you need real-time push plus periodic location updates.

### Use
1. Push stream (WebSocket/SSE) for events:
   - new request
   - request expired/cancelled
   - request accepted by someone else
   - ride state changed
2. Client periodic updates for driver location (`3-10s` cadence while online/active ride).

### Recommended model
- Event-driven for ride/request lifecycle.
- Timed location posting from app.
- Optional periodic snapshot pull as fallback (every `20-30s`) if socket drops.
