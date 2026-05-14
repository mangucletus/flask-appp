import socket

from flask import Flask, jsonify, render_template, request

app = Flask(__name__)

# Bumped whenever the app changes — surfaced in the UI and /echo response.
APP_VERSION = "v2"


@app.route("/")
def index():
    # Renders the landing page with server-side host + version info.
    return render_template(
        "index.html",
        message="Hello from Flask on AWS!",
        version=APP_VERSION,
        host=socket.gethostname(),
    )


@app.route("/echo", methods=["POST"])
def echo():
    # Echoes the request body back with the app version (handy for connectivity checks).
    data = request.get_json(silent=True) or {}
    return jsonify({"you_sent": data, "version": APP_VERSION})


@app.route("/health")
def health():
    # Lightweight readiness probe used by the ALB target group health check.
    return "ok", 200


if __name__ == "__main__":
    # Dev-only entry point — in production gunicorn imports `app:app` directly.
    app.run(host="0.0.0.0", port=8000)
