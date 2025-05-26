from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, db, messaging
import json
import os

firebase_credentials = json.loads(os.environ['GOOGLE_CREDENTIALS'])
cred = credentials.Certificate(firebase_credentials)
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://campus-transport-safety-default-rtdb.firebaseio.com/'
})

main = Flask(__name__)

@main.route('/send_sos', methods=['POST'])
def send_sos():
    data = request.get_json()
    institute = data.get('institute')
    bus_id = data.get('busId')

    # Get all users
    users_ref = db.reference('Users')
    users = users_ref.get()

    tokens = []
    for user_id, user_data in users.items():
        if user_data.get('institute') == institute and user_data.get('Role') == 1:
            token = user_data.get('fcmToken')
            if token:
                tokens.append(token)

    if not tokens:
        return jsonify({'message': 'No tokens found'}), 404

    # Send FCM message individually as fallback
    success_count = 0
    failure_count = 0
    
    for token in tokens:
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title="🚨 SOS Alert",
                    body=f"Emergency reported from Bus {bus_id} at {institute}",
                ),
                token=token
            )
            response = messaging.send(message)
            print(f"Sent message to {token}: {response}")
            success_count += 1
        except Exception as e:
            print(f"Failed to send message to {token}: {e}")
            failure_count += 1
    
    print(f"✅ Successfully sent: {success_count}, ❌ Failed: {failure_count}")

    return jsonify({'success': success_count, 'failure': failure_count})

if __name__ == '__main__':
    main.run(port=10000)
