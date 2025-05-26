from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, db, messaging

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://your-database.firebaseio.com'
})

app = Flask(__name__)

@app.route('/send_sos', methods=['POST'])
def send_sos():
    data = request.get_json()
    institute = data.get('institute')
    bus_id = data.get('busId')

    # Get all users
    users_ref = db.reference('users')
    users = users_ref.get()

    tokens = []
    for user_id, user_data in users.items():
        if user_data.get('institute') == institute and user_data.get('role') == 1:
            token = user_data.get('fcmToken')
            if token:
                tokens.append(token)

    if not tokens:
        return jsonify({'message': 'No tokens found'}), 404

    # Send FCM message
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title="🚨 SOS Alert",
            body=f"Emergency reported from Bus {bus_id} at {institute}",
        ),
        tokens=tokens
    )

    response = messaging.send_multicast(message)
    return jsonify({'success': response.success_count, 'failure': response.failure_count})

if __name__ == '__main__':
    app.run(port=5000)
