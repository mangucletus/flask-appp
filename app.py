import socket
from flask import Flask, jsonify, request, render_template

app = Flask(__name__)

APP_VERSION = "v1"


@app.route("/")
def index():
    return render_template(
        "index.html",
        message="Hello from Flask on AWS!",
        version=APP_VERSION,
        host=socket.gethostname(),
    )


@app.route("/echo", methods=["POST"])
def echo():
    data = request.get_json(silent=True) or {}
    return jsonify({"you_sent": data, "version": APP_VERSION})


@app.route("/health")
def health():
    return "ok", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
