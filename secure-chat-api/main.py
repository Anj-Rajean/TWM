from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict
import uvicorn
import json
import os

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_FILE = "database.json"

def load_db():
    if not os.path.exists(DB_FILE):
        return {"keys": {}, "history": {}}
    try:
        with open(DB_FILE, "r", encoding='utf-8') as f:
            data = json.load(f)
            return {"keys": data.get("keys", {}), "history": data.get("history", {})}
    except:
        return {"keys": {}, "history": {}}

def save_db(data):
    with open(DB_FILE, "w", encoding='utf-8') as f:
        json.dump(data, f, indent=4)

active_connections: Dict[str, WebSocket] = {}

class KeyRegistration(BaseModel):
    user_id: str
    public_key: str

def get_chat_id(id1: str, id2: str):
    return "_".join(sorted([id1, id2]))

@app.post("/register-key")
async def register_key(data: KeyRegistration):
    db = load_db()
    db["keys"][data.user_id] = data.public_key
    save_db(db)
    return {"status": "ok"}

@app.get("/get-key/{user_id}")
async def get_key(user_id: str):
    db = load_db()
    key = db["keys"].get(user_id)
    if not key: raise HTTPException(status_code=404)
    return {"public_key": key}

@app.get("/history/{user1}/{user2}")
async def get_history(user1: str, user2: str):
    db = load_db()
    chat_id = get_chat_id(user1, user2)
    return db["history"].get(chat_id, [])

@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await websocket.accept()
    active_connections[user_id] = websocket
    try:
        while True:
            data = await websocket.receive_json()
            target_id = data.get("to")
            db = load_db()
            chat_id = get_chat_id(user_id, target_id)
            if chat_id not in db["history"]: db["history"][chat_id] = []
            db["history"][chat_id].append(data)
            save_db(db)
            if target_id in active_connections:
                await active_connections[target_id].send_json(data)
    except WebSocketDisconnect:
        if user_id in active_connections: del active_connections[user_id]

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)