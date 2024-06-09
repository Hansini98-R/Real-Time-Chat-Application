from flask import Flask, render_template, redirect, url_for, request, session
from flask_socketio import SocketIO, join_room, leave_room, send
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user

app = Flask(__name__)
app.config['SECRET_KEY'] = 'Hansini98'
socketio = SocketIO(app)
login_manager = LoginManager()
login_manager.init_app(app)


users = {}

# User model
class User(UserMixin):
    def __init__(self, id):
        self.id = id

@login_manager.user_loader
def load_user(user_id):
    return User(user_id)

@app.route('/')
def index():
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        if username in users:
            user = users[username]
        else:
            user = User(username)
            users[username] = user
        login_user(user)
        return redirect(url_for('chat'))
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/chat')
@login_required
def chat():
    return render_template('chat.html', username=current_user.id)

@socketio.on('join')
def on_join(data):
    username = data['username']
    room = data['room']
    join_room(room)
    send(f'{username} has entered the room.', to=room)

@socketio.on('leave')
def on_leave(data):
    username = data['username']
    room = data['room']
    leave_room(room)
    send(f'{username} has left the room.', to=room)

@socketio.on('message')
def handle_message(data):
    room = data['room']
    send(data['message'], to=room)

if __name__ == '__main__':
    socketio.run(app, debug=True)
