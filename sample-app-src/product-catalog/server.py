from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/listproducts")
def list_products():
    # Minimal static catalog for demo purposes
    return jsonify(
        products=[
            {"id": "1", "name": "Demo Product", "price": 10.0}
        ]
    )

@app.get("/health")
def health():
    return jsonify(status="ok")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3550)
